// ==============================================================================
// 🚀 MONGODB (NOSQL) SYNTAX & AGGREGATION PRACTICE GUIDE
// ==============================================================================
// Run these commands inside the Mongosh shell.
//
// Access Mongosh via Docker CLI:
//   docker exec -it nosql_interview_mongo mongosh -u admin -p adminpassword
//
// Switch to the interview database:
//   use interview_nosql;
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. BASIC CRUD & DOCUMENT FINDING
// Find all active employees in the Engineering department.
// ------------------------------------------------------------------------------
db.employees.find({
  department: "Engineering",
  status: "Active"
});

// ------------------------------------------------------------------------------
// 2. PROJECTION & SORTING
// Select only first_name, last_name, and salary (exclude _id), sorted by salary DESC.
// ------------------------------------------------------------------------------
db.employees.find(
  { salary: { $gte: 75000 } },
  { _id: 0, first_name: 1, last_name: 1, salary: 1, department: 1 }
).sort({ salary: -1 });

// ------------------------------------------------------------------------------
// 3. ARRAY QUERYING ($elemMatch & $in)
// Find employees who possess both "MongoDB" skill or live in San Francisco.
// ------------------------------------------------------------------------------
db.employees.find({
  skills: { $in: ["MongoDB"] },
  "address.city": "San Francisco"
});

// ------------------------------------------------------------------------------
// 4. AGGREGATION PIPELINE: $match, $group, $sort (Group by Department)
// Calculate total employees, average salary, and max salary per department.
// ------------------------------------------------------------------------------
db.employees.aggregate([
  {
    $match: { status: "Active" }
  },
  {
    $group: {
      _id: "$department",
      total_employees: { $sum: 1 },
      avg_salary: { $avg: "$salary" },
      max_salary: { $max: "$salary" }
    }
  },
  {
    $sort: { avg_salary: -1 }
  }
]);

// ------------------------------------------------------------------------------
// 5. UNWINDING ARRAYS ($unwind & $group)
// Count the frequency of each skill across all employees.
// ------------------------------------------------------------------------------
db.employees.aggregate([
  { $unwind: "$skills" },
  {
    $group: {
      _id: "$skills",
      employee_count: { $sum: 1 }
    }
  },
  { $sort: { employee_count: -1 } }
]);

// ------------------------------------------------------------------------------
// 6. NOSQL JOIN ($lookup across collections)
// Join Projects collection with Employees collection on lead_employee_id == employee_id.
// ------------------------------------------------------------------------------
db.projects.aggregate([
  {
    $lookup: {
      from: "employees",
      localField: "lead_employee_id",
      foreignField: "employee_id",
      as: "lead_details"
    }
  },
  {
    $unwind: "$lead_details"
  },
  {
    $project: {
      _id: 0,
      project_id: 1,
      project_name: "$name",
      budget: 1,
      lead_name: { $concat: ["$lead_details.first_name", " ", "$lead_details.last_name"] },
      lead_department: "$lead_details.department"
    }
  }
]);

// ------------------------------------------------------------------------------
// 7. UPDATES & INDEX CREATION
// Add a new skill to Ethan Hunt and create an index on department + salary.
// ------------------------------------------------------------------------------
db.employees.updateOne(
  { employee_id: 105 },
  { $addToSet: { skills: "GraphQL" } }
);

db.employees.createIndex({ department: 1, salary: -1 });
