import 'dart:math';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:langchain/langchain.dart';

/// 持久化向量存储 - 使用 Sembast 数据库存储向量
/// 
/// 功能：
/// 1. 持久化存储文档和向量嵌入
/// 2. 支持余弦相似度搜索
/// 3. 增量同步（只添加新文档）
class PersistentVectorStore {
  Database? _db;
  StoreRef<String, Map<String, dynamic>>? _store;
  Embeddings? _embeddings;
  bool _initialized = false;

  /// 初始化数据库
  Future<void> initialize(Embeddings embeddings) async {
    if (_initialized) return;

    _embeddings = embeddings;
    
    // 获取应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, 'vector_store.db');
    
    // 打开数据库
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _store = stringMapStoreFactory.store('vectors');
    
    _initialized = true;
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 添加文档到向量存储
  Future<List<Document>> addDocuments({
    required final List<Document> documents,
    final List<List<double>>? embeddings,
  }) async {
    if (!_initialized) throw Exception('VectorStore 未初始化');
    if (_embeddings == null) throw Exception('Embeddings 未设置');

    // 生成嵌入（如果未提供）
    List<List<double>> docsEmbeddings;
    if (embeddings != null && embeddings.length == documents.length) {
      docsEmbeddings = embeddings;
    } else {
      docsEmbeddings = await _embeddings!.embedDocuments(documents);
    }

    // 批量写入数据库
    await _db!.transaction((txn) async {
      for (var i = 0; i < documents.length; i++) {
        final doc = documents[i];
        final embedding = docsEmbeddings[i];
        
        await _store!.record(doc.id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}_$i').put(txn, {
          'content': doc.pageContent,
          'metadata': doc.metadata,
          'embedding': embedding,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    return documents;
  }

  /// 添加文本到向量存储
  Future<List<String>> addTexts({
    required final List<String> texts,
    final List<Map<String, dynamic>>? metadatas,
    final List<List<double>>? embeddings,
  }) async {
    final documents = texts.asMap().entries.map((entry) {
      final i = entry.key;
      final text = entry.value;
      return Document(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}_$i',
        pageContent: text,
        metadata: metadatas != null && i < metadatas.length ? metadatas[i] : {},
      );
    }).toList();

    await addDocuments(documents: documents, embeddings: embeddings);
    return documents.map((d) => d.id!).toList();
  }

  /// 基于向量相似度搜索（带分数）
  Future<List<(Document, double)>> similaritySearchByVectorWithScores({
    required final List<double> embedding,
    final int k = 4,
  }) async {
    if (!_initialized) throw Exception('VectorStore 未初始化');

    // 获取所有文档
    final records = await _store!.find(_db!);
    
    // 计算余弦相似度并排序
    final List<(Document, double)> scoredDocs = [];
    
    for (final record in records) {
      final data = record.value;
      
      // 安全地转换 embedding，处理从数据库读取的 List<dynamic>
      final embeddingRaw = data['embedding'];
      if (embeddingRaw == null || embeddingRaw is! List) continue;
      
      final storedEmbedding = embeddingRaw.map((e) => (e as num).toDouble()).toList();
      
      // 计算余弦相似度
      final similarity = _cosineSimilarity(embedding, storedEmbedding);
      
      final doc = Document(
        id: record.key,
        pageContent: data['content'] as String? ?? '',
        metadata: (data['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      
      scoredDocs.add((doc, similarity));
    }

    // 按相似度降序排序并取前 k 个
    scoredDocs.sort((a, b) => b.$2.compareTo(a.$2));
    return scoredDocs.take(k).toList();
  }

  /// 基于向量相似度搜索
  Future<List<Document>> similaritySearchByVector({
    required final List<double> embedding,
    final int k = 4,
  }) async {
    final results = await similaritySearchByVectorWithScores(
      embedding: embedding,
      k: k,
    );
    return results.map((r) => r.$1).toList();
  }

  /// 基于查询文本相似度搜索（带分数）
  Future<List<(Document, double)>> similaritySearchWithScores({
    required final String query,
    final int k = 4,
  }) async {
    if (!_initialized) throw Exception('VectorStore 未初始化');
    if (_embeddings == null) throw Exception('Embeddings 未设置');

    // 生成查询嵌入
    final queryEmbedding = await _embeddings!.embedQuery(query);
    return similaritySearchByVectorWithScores(
      embedding: queryEmbedding,
      k: k,
    );
  }

  /// 基于查询文本相似度搜索
  Future<List<Document>> similaritySearch({
    required final String query,
    final int k = 4,
  }) async {
    final results = await similaritySearchWithScores(query: query, k: k);
    return results.map((r) => r.$1).toList();
  }

  /// 计算余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('向量维度不匹配: ${a.length} vs ${b.length}');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// 获取所有文档数量
  Future<int> get documentCount async {
    if (!_initialized) return 0;
    return await _store!.count(_db!);
  }

  /// 删除指定 ID 的文档
  Future<void> deleteDocument(String id) async {
    if (!_initialized) return;
    await _store!.record(id).delete(_db!);
  }

  /// 清空所有文档
  Future<void> clear() async {
    if (!_initialized) return;
    await _store!.delete(_db!);
  }

  /// 获取最后更新时间
  Future<DateTime?> getLastUpdateTime() async {
    if (!_initialized) return null;
    
    final records = await _store!.find(_db!);
    if (records.isEmpty) return null;

    DateTime? lastTime;
    for (final record in records) {
      final timestamp = record.value['timestamp'] as String?;
      if (timestamp != null) {
        final time = DateTime.parse(timestamp);
        if (lastTime == null || time.isAfter(lastTime)) {
          lastTime = time;
        }
      }
    }
    return lastTime;
  }

  /// 检查文档是否已存在
  Future<bool> hasDocument(String id) async {
    if (!_initialized) return false;
    final record = await _store!.record(id).get(_db!);
    return record != null;
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_initialized && _db != null) {
      await _db!.close();
      _initialized = false;
    }
  }
}
