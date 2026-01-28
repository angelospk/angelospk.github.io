+++
title = "Gemini RAG Demo"
description = "Greek FEK Document Q&A System"
date = "2026-01"
tags = ["Python", "LangChain", "Gemini API", "FAISS", "RAG", "NLP"]
categories = ["ai"]
weight = 8
+++

# Gemini RAG Demo

**Greek FEK Document Q&A System**

## Overview

RAG (Retrieval-Augmented Generation) system that answers questions based on Greek FEK (Government Gazette) PDF documents, using Gemini for embeddings and generation.

Greek legal documents (ΦΕΚ) are dense and difficult to navigate. Finding specific information requires manual reading of multiple documents.

Built a RAG pipeline that indexes PDF documents, stores semantic embeddings in FAISS, and uses Gemini 2.5 Flash to answer questions with source citations.

## Key Features

- **PDF Ingestion Pipeline**: Reads and chunks PDF documents using LangChain, optimized for Greek text.
- **Gemini Embeddings**: Uses text-embedding-004 with native Greek language support.
- **FAISS Vector Store**: Local vector database for fast similarity search.
- **Source Citations**: Returns answers with references to specific documents and pages.
- **Google Colab Support**: Includes notebook for easy cloud-based experimentation.

## How It Works

1. **Ingestion**: PDFs are read and split into small chunks
2. **Embeddings**: Each chunk is converted to a vector with Gemini text-embedding-004 (supports Greek!)
3. **Storage**: Vectors are stored in FAISS (local vector database)
4. **Query**: When you ask a question:
   - Finds the most relevant chunks (similarity search)
   - Sends them to Gemini along with the question
   - Returns an answer based on the documents

## Technologies

- **LangChain** - RAG framework (LCEL chains, document loaders, text splitters)
- **FAISS** - Vector database (local, by Meta AI)
- **Gemini text-embedding-004** - Embeddings (supports Greek)
- **Gemini 2.5 Flash** - LLM for generation
- **PyPDF** - PDF parsing

## Links

- [GitHub](https://github.com/angelospk/gemini-rag-demo)
- [Open in Colab](https://colab.research.google.com/github/angelospk/gemini-rag-demo/blob/main/rag_demo.ipynb)
