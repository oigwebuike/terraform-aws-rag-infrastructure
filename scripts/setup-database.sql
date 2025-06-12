# scripts/setup-database.sql

-- Setup script for PostgreSQL with pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Create documents table for storing embeddings
CREATE TABLE IF NOT EXISTS documents (
    id VARCHAR(255) PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536), -- Adjust dimension based on your embedding model
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for vector similarity search
CREATE INDEX IF NOT EXISTS documents_embedding_idx 
ON documents USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Create function for similarity search
CREATE OR REPLACE FUNCTION search_similar_documents(
    query_embedding vector(1536),
    similarity_threshold float DEFAULT 0.8,
    max_results int DEFAULT 10
)
RETURNS TABLE(
    id VARCHAR(255),
    content TEXT,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.content,
        1 - (d.embedding <=> query_embedding) as similarity
    FROM documents d
    WHERE 1 - (d.embedding <=> query_embedding) > similarity_threshold
    ORDER BY d.embedding <=> query_embedding
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;
