# Feature Engineering

If you want your AI models to work well—whether for search, recommendations, or anything else—you need good data. But raw data is usually messy and incomplete. Before you can train a model or use it for search, you have to turn that raw data into clear, meaningful features.

Feature engineering is the process of cleaning up your data and creating new signals that actually help your model learn or make better predictions. This step is just as important for preparing training data as it is for powering your AI in production.

It can take some work to get from raw data to useful features. Let’s look at a simple example to see why this matters and how it’s done.

## The Manual Workflow: A E-commerce Recommendation System 🛍️

Imagine we are building a product recommendation system for a large e-commerce platform. The goal is to find items that are genuinely "similar" to a product a user is currently viewing. This notion of "similarity" must be sophisticated, going far beyond a simple text match on the product description. It needs to incorporate nuanced business concepts like popularity, value, brand equity, and key product attributes.

### Step 1: The Raw Data Table

We start with a raw data table in our data lakehouse, which we'll call `products_raw`. This table contains the basic, unprocessed information scraped from our product catalog. An embedding model could be applied directly to the `description` column for semantic search, but that would only capture a fraction of the story.

**Table: `products_raw`**

| product_id | title | description | category | price | original_price | review_count | avg_rating |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | V-Neck Tee | "A soft, 100% cotton v-neck shirt." | T-Shirt | 25.00 | 25.00 | 1200 | 4.8 |
| 102 | Designer Tee | "Limited edition organic cotton tee." | T-Shirt | 90.00 | 150.00 | 25 | 4.9 |
| 103 | New Tee | "A new v-neck t-shirt." | T-Shirt | 22.00 | 22.00 | 1 | 5.0 |

### Step 2: The Problem with Raw Data

Using this raw data to generate embeddings for a recommendation model is destined for failure. Critical business signals that define true product similarity are either misleading, hidden, or entirely absent:

* **Misleading Popularity:** The "New Tee" boasts a perfect 5.0 rating, but with only a single review. Is it truly more "popular" or "better" than the "V-Neck Tee" with 1200 reviews and a 4.8 rating? A naive model would think so, leading to poor recommendations.
* **Missing Price Context:** The model sees a price of $90.00 for the "Designer Tee," but it has no intrinsic understanding that this represents a steep 40% discount, a powerful purchasing signal. It also doesn't know how this price compares to the average price of other T-shirts.
* **Hidden Attributes:** Key attributes like "organic" or "limited edition" are buried within the free-text `description`. They are invisible to any model that doesn't perform sophisticated text analysis, yet they are crucial for matching user preferences.

### Step 3: Manual Feature engineering

To address these challenges, a data scientist or ML engineer typically embarks on a manual, code-intensive journey to extract hidden signals and craft new, meaningful features. This process often takes place in a Jupyter notebook and involves several intricate steps:

1. **Engineer `popularity_score`:**  
   To create a more accurate measure of popularity, combine the average rating with the volume of reviews. A common approach is to use logarithmic scaling, which prevents products with massive review counts from overwhelming the score.
   - **Logic:**  
     ```python
     popularity_score = log(review_count + 1) * avg_rating
     ```

2. **Engineer `price_tier`:**  
   To help the model understand value, bucket raw prices into clear tiers such as 'budget', 'mid-range', or 'premium'.
   - **Logic:**  
     Use conditional logic (e.g., `CASE WHEN` in SQL or `np.select` in Python) to assign a tier based on price thresholds.

3. **Engineer `discount_pct`:**  
   To explicitly signal a "deal" to the model, calculate the discount percentage by combining the original and current prices.
   - **Logic:**  
     ```python
     discount_pct = (original_price - price) / original_price
     ```

4. **Engineer `price_vs_cat_avg`:**  
   To contextualize a product's price, compare it to the average price within its category. This requires an aggregation step to compute the average price per category before calculating the feature for each product.
   - **Logic:**  
     For each product:
     ```python
     price_vs_cat_avg = price / avg_price_for_category
     ```

5. **Engineer `is_organic`:**  
   To surface key product attributes, process the `description` text to identify important keywords.
   - **Logic:**  
     Use a regular expression or string search for the keyword "organic" to create a boolean (`true`/`false`) flag.

Each of these steps requires careful data manipulation, domain knowledge, and iterative experimentation to ensure the resulting features are both accurate and useful for downstream models.

### Step 4: The Enriched Table

After executing this complex chain of logic, we produce a new, enriched table. The features in this table are more potent and ready to be fed into an embedding model to produce high-quality vectors for our recommendation system.

**Table: `products_engineered`**

| product_id |... | popularity_score | price_tier | discount_pct | price_vs_cat_avg | is_organic |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 |... | 33.6 | 'budget' | 0.0 | 0.54 | false |
| 102 |... | 15.9 | 'premium' | 0.4 | 1.95 | true |
| 103 |... | 3.5 | 'budget' | 0.0 | 0.47 | false |

## The Real Challenge: Scaling Feature Engineering

While manual feature engineering works for small datasets, **things change dramatically at scale**. In real-world production systems, you often need to process tens or hundreds of millions of records, sometimes in real time. The logic that was simple in a notebook—like aggregations, conditional logic, or text processing—becomes much harder to manage and execute efficiently.

**As data grows, so does complexity**. You might need to generate features from new sources, such as user behavior logs, images, or videos. This can involve running large-scale machine learning models for tasks like image captioning or text embedding, which require significant compute resources and robust infrastructure.

Managing this at scale means dealing with distributed systems, scheduling, monitoring, and ensuring that feature pipelines are reliable and reproducible. Experimenting with new features or updating existing ones can require major engineering work, slowing down iteration and innovation. Infrastructure challenges—like orchestrating batch and streaming jobs, handling dependencies, and scaling inference—often become the main bottleneck.

In short, the biggest challenge in modern feature engineering is not just coming up with good features, but building infrastructure that can handle complex, multi-modal operations and deliver fresh, high-quality features quickly and reliably at massive scale. This is what Geneva solves. Learn more in the next section.
