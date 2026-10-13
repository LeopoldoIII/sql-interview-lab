# 🍃 Complete MongoDB Guide (NoSQL): Queries & Aggregations

This guide accompanies the **MongoDB 7.0** container (`nosql_interview_mongo`) and the `interview_nosql` database pre-seeded via `mongo_init/01_init_nosql.js`.

---

## ⚡ Quick Connection

Connect to the interactive `mongosh` shell inside the Docker container:

```bash
docker exec -it nosql_interview_mongo mongosh -u admin -p adminpassword --authenticationDatabase admin
```

Inside mongosh, switch to the practice database:
```javascript
use interview_nosql;
```

> 💡 **Tip:** You can also run the companion script [mongo_practice.js](file:///Users/usermone/local/projects/sql/sql-interview-lab/mongo_practice.js) via MongoDB Compass or your favorite database GUI by connecting to `mongodb://admin:adminpassword@localhost:27017/interview_nosql?authSource=admin`.

---

## 📊 Document Schema & Collections

### Collection: `employees`
```json
{
  "employee_id": 101,
  "first_name": "Alice",
  "last_name": "Smith",
  "department": "Engineering",
  "salary": 85000,
  "skills": ["JavaScript", "Python", "MongoDB"],
  "hire_date": ISODate("2021-03-15T00:00:00Z"),
  "address": { "city": "San Francisco", "state": "CA" },
  "status": "Active"
}
```

### Collection: `projects`
```json
{
  "project_id": "PROJ-1",
  "name": "Cloud Migration",
  "lead_employee_id": 102,
  "budget": 150000,
  "tags": ["Cloud", "DevOps"],
  "status": "In Progress"
}
```

---

## 📌 Module 1: Basic Queries (`find`, Operators & Arrays)

### 1.1 Basic Filtering and Projection
The first argument is the **filter criteria**, and the second argument is the **projection** (`1` to include, `0` to exclude):

```javascript
// Retrieve first names, last names, and salaries of active employees
db.employees.find(
  { status: "Active" },
  { _id: 0, first_name: 1, last_name: 1, salary: 1 }
);
```

### 1.2 Comparison Operators (`$gt`, `$gte`, `$in`)
```javascript
// Employees earning 75,000 or more in Engineering or Data & Analytics
db.employees.find({
  salary: { $gte: 75000 },
  department: { $in: ["Engineering", "Data & Analytics"] }
});
```

### 1.3 Querying Embedded Documents and Arrays
MongoDB allows deep dot-notation queries on nested subdocuments (`"address.city"`), and direct matching on array elements:

```javascript
// Employees living in San Francisco with "MongoDB" skill
db.employees.find({
  "address.city": "San Francisco",
  skills: "MongoDB"
});

// Employees who possess BOTH "Python" AND "MongoDB" skills ($all)
db.employees.find({
  skills: { $all: ["Python", "MongoDB"] }
});
```

---

## 📌 Module 2: The Aggregation Pipeline (`aggregate`)

The aggregation pipeline models data transformations as a multi-stage flow (`stages`). Each stage transforms the input documents and passes the result to the next.

### Key Pipeline Stages:
* **`$match`**: Filters documents (SQL equivalent of `WHERE`).
* **`$group`**: Groups documents by key and computes metrics (SQL equivalent of `GROUP BY`).
* **`$project`**: Shapes output documents (SQL equivalent of `SELECT`).
* **`$sort`**: Sorts results (`1` ascending, `-1` descending).
* **`$unwind`**: Deconstructs an array field from the input documents to output a document for each element.
* **`$lookup`**: Performs a left outer join to an unsharded collection.

---

### 2.1 Department Salary Breakdown
```javascript
db.employees.aggregate([
  { $match: { status: "Active" } },
  {
    $group: {
      _id: "$department",
      total_employees: { $sum: 1 },
      avg_salary: { $avg: "$salary" },
      max_salary: { $max: "$salary" }
    }
  },
  { $sort: { avg_salary: -1 } }
]);
```

---

### 2.2 Array Deconstruction with `$unwind` (Skill Popularity Count)
How many employees possess each unique skill in the company?

```javascript
db.employees.aggregate([
  // 1. Unwind skills array
  { $unwind: "$skills" },
  // 2. Group by individual skill
  {
    $group: {
      _id: "$skills",
      employee_count: { $sum: 1 }
    }
  },
  // 3. Sort from most popular to least
  { $sort: { employee_count: -1 } }
]);
```

---

### 2.3 NoSQL JOIN with `$lookup` (Projects with Team Lead Details)
Equivalent to `projects LEFT JOIN employees ON projects.lead_employee_id = employees.employee_id`:

```javascript
db.projects.aggregate([
  {
    $lookup: {
      from: "employees",
      localField: "lead_employee_id",
      foreignField: "employee_id",
      as: "leader"
    }
  },
  // $lookup returns an array; $unwind flattens it to an object
  { $unwind: "$leader" },
  {
    $project: {
      _id: 0,
      project_name: "$name",
      budget: "$budget",
      leader_name: { $concat: ["$leader.first_name", " ", "$leader.last_name"] },
      leader_department: "$leader.department"
    }
  }
]);
```

## 📌 Module 3: Finding, Handling & Preventing Duplicates in NoSQL

Unlike relational databases with strict schema constraints, NoSQL document stores often experience duplicates due to schema flexibility, distributed event retries, or lack of cross-document foreign keys.

---

### 3.1 Detecting Duplicates with the Aggregation Pipeline
The direct MongoDB equivalent to SQL's `GROUP BY ... HAVING COUNT(*) > 1` is `$group` combined with `$match`:

```javascript
// Detect duplicate employees by email or composite name
db.employees.aggregate([
  {
    $group: {
      _id: { firstName: "$first_name", lastName: "$last_name" }, // grouping key
      duplicate_count: { $sum: 1 },
      document_ids: { $push: "$_id" },                            // collect all ObjectIds
      salaries: { $push: "$salary" }
    }
  },
  {
    $match: {
      duplicate_count: { $gt: 1 }                                 // filter only duplicates
    }
  }
]);
```

---

### 3.2 Deduplicating & Deleting Redundant Documents
To delete duplicates while **keeping the original (first created)** document:

```javascript
// Step 1: Find groups with more than 1 occurrence
db.employees.aggregate([
  {
    $group: {
      _id: { firstName: "$first_name", lastName: "$last_name" },
      count: { $sum: 1 },
      ids: { $push: "$_id" }
    }
  },
  { $match: { count: { $gt: 1 } } }
]).forEach(function(doc) {
  // Discard the first element (the original), delete all subsequent copies
  doc.ids.shift(); 
  db.employees.deleteMany({ _id: { $in: doc.ids } });
});
```

---

### 3.3 Deduplication Inside Document Arrays (`$addToSet` vs `$push`)
In document databases, duplicates often happen **inside arrays** of a single document (e.g. `skills`, `tags`):

* **`$push`**: Appends elements unconditionally, **allowing duplicates**.
* **`$addToSet`**: Treats the array like a mathematical set, appending an element **only if it does not already exist**.

```javascript
// Safely add skills without creating duplicates:
db.employees.updateOne(
  { employee_id: 101 },
  { $addToSet: { skills: "Docker" } } // Will not add "Docker" if it already exists
);

// Add multiple unique skills at once ($each):
db.employees.updateOne(
  { employee_id: 101 },
  { $addToSet: { skills: { $each: ["Kubernetes", "Docker", "AWS"] } } }
);
```

---

### 3.4 Prevention at Database Level: Unique Indexes
To prevent duplicates from ever being inserted into a collection:

```javascript
// Single-field unique index:
db.employees.createIndex({ employee_id: 1 }, { unique: true });

// Compound unique index (first_name + last_name):
db.employees.createIndex({ first_name: 1, last_name: 1 }, { unique: true });

// Sparse unique index (only enforces uniqueness when the field exists and is not null):
db.employees.createIndex({ "address.zipcode": 1 }, { unique: true, sparse: true });
```

---

## 🎯 MongoDB Practice Challenges

#### Challenge 1: Total Project Budget by Status
> **Question:** Write an aggregation query on `projects` grouping by `status` to compute total budget (`total_budget`) and the count of projects in each status.

<details>
<summary>🔍 View Solution</summary>

```javascript
db.projects.aggregate([
  {
    $group: {
      _id: "$status",
      project_count: { $sum: 1 },
      total_budget: { $sum: "$budget" }
    }
  },
  { $sort: { total_budget: -1 } }
]);
```
</details>

#### Challenge 2: Employees with at least 3 Skills
> **Question:** Find all employees whose `skills` array contains 3 or more items.

<details>
<summary>🔍 View Solution</summary>

```javascript
// Using $expr and $size
db.employees.find({
  $expr: { $gte: [{ $size: "$skills" }, 3] }
});
```
</details>

#### Challenge 3: Detect Duplicate Project Budgets
> **Question:** Write an aggregation query on `projects` to identify if any projects share the exact same `budget`. Return the budget value, how many projects share it, and the list of project names.

<details>
<summary>🔍 View Solution</summary>

```javascript
db.projects.aggregate([
  {
    $group: {
      _id: "$budget",
      count: { $sum: 1 },
      project_names: { $push: "$name" }
    }
  },
  { $match: { count: { $gt: 1 } } }
]);
```
</details>

