---
title: Gemini RAG Demo
description: Greek FEK Document Q&A System
weight: 8
tags:
- Python
- LangChain
- Gemini API
- FAISS
- RAG
- Embeddings
- NLP
categories:
- ai
---

Answers questions about Greek Government Gazette (FEK) PDFs with the document and page reference for every answer, so a reader can check the source instead of trusting the model. Retrieval uses Gemini embeddings, FAISS and LangChain over dense Greek legal text.

## The problem

Greek legal documents (ΦΕΚ) are dense and difficult to navigate. 
Finding specific information requires manual reading of multiple documents.

## What I built

Built a RAG pipeline that indexes PDF documents, stores semantic embeddings 
in FAISS, and uses Gemini 2.5 Flash to answer questions with source citations.

## Implementation

- Implemented PDF ingestion, chunking and vector retrieval with Python, LangChain and FAISS.
- Returned source document and page references alongside generated answers.
- Included a Colab notebook for reproducing the workflow; citation correctness and abstention remain evaluation priorities.

## Links

- [GitHub](https://github.com/angelospk/gemini-rag-demo)
- [Open in Colab](https://colab.research.google.com/github/angelospk/gemini-rag-demo/blob/main/rag_demo.ipynb)
