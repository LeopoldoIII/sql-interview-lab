# MongoDB 7.0 Pipeline & Indexing Patterns

## 1. The ESR (Equality, Sort, Range) Compound Index Rule

When creating compound indexes in MongoDB, field order dictates whether the query planner can avoid an in-memory blocking `SORT` stage and minimize scanned keys:

1. **Equality:** Fields matched with exact values (`{ department: "Engineering", status: "Active" }`).
2. **Sort:** Fields used in `.sort()` or `{ $sort: { hire_date: -1 } }`.
3. **Range:** Fields filtered with `$gt`, `$gte`, `$lt`, `$lte`, `$in`, or `$ne` (`{ salary: { $gte: 80000 } }`).

```javascript
// Query with Equality (department, status), Sort (hire_date DESC), and Range (salary >= 80000)
db.employees.find(
  {
    status: "Active",
    department: "Engineering",
    salary: { $gte: 80000 }
  },
  { _id: 0, employee_id: 1, first_name: 1, salary: 1, hire_date: 1 }
).sort({ hire_date: -1 });

// ✅ Optimal ESR Index: Equality (status, department) -> Sort (hire_date) -> Range (salary)
db.employees.createIndex({
  status: 1,
  department: 1,
  hire_date: -1,
  salary: 1
});
```

---

## 2. Expressive `$lookup` with Sub-Pipelines

Instead of joining entire foreign documents and unwinding everything, use `$lookup` with `let` and `pipeline` to filter and project the joined collection inside the lookup:

```javascript
// ✅ Best Practice: Filtered & Projected $lookup
db.employees.aggregate([
  { $match: { status: "Active", department: "Engineering" } },
  {
    $lookup: {
      from: "projects",
      let: { empId: "$employee_id" },
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$lead_employee_id", "$$empId"] },
                { $eq: ["$status", "In Progress"] }
              ]
            }
          }
        },
        { $project: { _id: 0, project_id: 1, name: 1, budget: 1 } }
      ],
      as: "active_led_projects"
    }
  },
  {
    $project: {
      _id: 0,
      employee_id: 1,
      full_name: { $concat: ["$first_name", " ", "$last_name"] },
      active_led_projects: 1
    }
  }
]);
```

---

## 3. Array Filtering: `$all` vs `$in` vs `$elemMatch`

- `$in: ["MongoDB", "Redis"]`: Matches if the array contains **at least one** of the values (`OR`).
- `$all: ["MongoDB", "Python"]`: Matches if the array contains **all** specified values (`AND`).
- `$elemMatch`: Required when matching **multiple criteria on the same array element** (especially arrays of subdocuments).

```javascript
// Find employees who possess BOTH "MongoDB" AND "Python" skills
db.employees.find(
  { skills: { $all: ["MongoDB", "Python"] } },
  { _id: 0, first_name: 1, last_name: 1, skills: 1 }
);
```

---

## 4. Single-Pass Multi-Faceted Analytics (`$facet`)

Use `$facet` when an interview problem asks for multiple aggregations (e.g., department breakdown AND top earners AND skill distribution) in a single database roundtrip:

```javascript
db.employees.aggregate([
  { $match: { status: "Active" } },
  {
    $facet: {
      by_department: [
        {
          $group: {
            _id: "$department",
            headcount: { $sum: 1 },
            avg_salary: { $avg: "$salary" }
          }
        },
        { $sort: { avg_salary: -1 } }
      ],
      top_earners: [
        { $sort: { salary: -1 } },
        { $limit: 3 },
        { $project: { _id: 0, first_name: 1, last_name: 1, salary: 1 } }
      ]
    }
  }
]);
```

