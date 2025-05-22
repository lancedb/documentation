---
title: Overview of Tables in LanceDB
description: Introduction to tables in LanceDB and basic concepts for managing vector data.
---

# Overview of Tables in LanceDB

A Table is a collection of Records in a LanceDB Database. Tables in Lance have a schema that defines the columns and their types. These schemas can include nested columns and can evolve over time.

## Key Concepts

- **Tables**: The fundamental unit of data organization in LanceDB, containing records with a defined schema
- **Schema**: Defines the structure of your data, including column names, data types, and whether fields are required
- **Vector Column**: A special column type that stores vector embeddings for similarity search
- **Metadata Columns**: Regular columns that store additional information about each record
- **Versioning**: Tables maintain versions as they are modified, enabling point-in-time queries

## Operations Overview

LanceDB provides comprehensive table management capabilities:

- **Creation**: Create tables from various data sources including lists, DataFrames, and Pydantic models
- **Modification**: Add, update, or delete data with support for batch operations
- **Schema Management**: Add, alter, or drop columns as your data needs evolve
- **Consistency Control**: Configure read consistency settings for your use case


!!! note "Legacy Javascript SDK"
    The `vectordb` package is a legacy package that is deprecated in favor of `@lancedb/lancedb`. The `vectordb` package will continue to receive bug fixes and security updates until September 2024. We recommend all new projects use `@lancedb/lancedb`. 