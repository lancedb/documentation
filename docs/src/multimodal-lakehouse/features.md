# Feature Engineering

Geneva improves the productivity of AI engineers by streamlining feature engineering tasks.  It is designed to reduce the time required to prototype, perform experiments, scale up, and move to production.

Geneva uses Python User Defined Functions (**UDFs**) to define features as columns in a Lance dataset.  Adding a feature is straightforward:

1. Prototype your Python function in your favorite environment.
2. Wrap the function with small UDF decorator.
3. Register the UDF as a virtual column using `Table.add_columns()`.
4. Trigger a backfill operation.

## Prototyping your Python function

Build your Python feature generator function in an IDE or notebook using your project's Python versions and dependencies.

*That's it.*

Geneva will automate much of the dependency and version management needed to move from prototype to scale and production.

