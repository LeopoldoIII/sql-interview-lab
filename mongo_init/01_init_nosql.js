// MongoDB Initial Seed Script for interview_nosql database
db = db.getSiblingDB('interview_nosql');

// Drop existing collections to ensure clean state
db.employees.drop();
db.projects.drop();
db.activity_logs.drop();

// Seed Employees collection
db.employees.insertMany([
  {
    employee_id: 101,
    first_name: "Alice",
    last_name: "Smith",
    department: "Engineering",
    salary: 85000,
    skills: ["JavaScript", "Python", "MongoDB"],
    hire_date: ISODate("2021-03-15T00:00:00Z"),
    address: { city: "San Francisco", state: "CA" },
    status: "Active"
  },
  {
    employee_id: 102,
    first_name: "Bob",
    last_name: "Johnson",
    department: "Engineering",
    salary: 92000,
    skills: ["Java", "Docker", "Kubernetes", "MongoDB"],
    hire_date: ISODate("2020-06-01T00:00:00Z"),
    address: { city: "Austin", state: "TX" },
    status: "Active"
  },
  {
    employee_id: 103,
    first_name: "Charlie",
    last_name: "Brown",
    department: "Sales",
    salary: 65000,
    skills: ["CRM", "Negotiation"],
    hire_date: ISODate("2022-01-10T00:00:00Z"),
    address: { city: "New York", state: "NY" },
    status: "Active"
  },
  {
    employee_id: 104,
    first_name: "Diana",
    last_name: "Prince",
    department: "Marketing",
    salary: 70000,
    skills: ["SEO", "Content", "Analytics"],
    hire_date: ISODate("2023-04-20T00:00:00Z"),
    address: { city: "Chicago", state: "IL" },
    status: "Active"
  },
  {
    employee_id: 105,
    first_name: "Ethan",
    last_name: "Hunt",
    department: "Engineering",
    salary: 110000,
    skills: ["Go", "Distributed Systems", "MongoDB"],
    hire_date: ISODate("2019-11-05T00:00:00Z"),
    address: { city: "San Francisco", state: "CA" },
    status: "Active"
  }
]);

// Seed Projects collection
db.projects.insertMany([
  {
    project_id: "PROJ-1",
    name: "Cloud Migration",
    lead_employee_id: 102,
    budget: 150000,
    tags: ["Cloud", "DevOps"],
    status: "In Progress"
  },
  {
    project_id: "PROJ-2",
    name: "NoSQL Lab Platform",
    lead_employee_id: 101,
    budget: 80000,
    tags: ["Database", "Backend"],
    status: "Completed"
  },
  {
    project_id: "PROJ-3",
    name: "Global Marketing Campaign",
    lead_employee_id: 104,
    budget: 50000,
    tags: ["Marketing", "Global"],
    status: "In Progress"
  }
]);

// Seed Activity Logs collection
db.activity_logs.insertMany([
  { employee_id: 101, action: "LOGIN", timestamp: ISODate("2024-01-15T08:30:00Z") },
  { employee_id: 101, action: "QUERY_EXECUTION", query: "find()", timestamp: ISODate("2024-01-15T08:35:00Z") },
  { employee_id: 102, action: "LOGIN", timestamp: ISODate("2024-01-15T09:00:00Z") },
  { employee_id: 103, action: "UPDATE_PROFILE", timestamp: ISODate("2024-01-15T09:15:00Z") }
]);

print("MongoDB interview_nosql database pre-populated successfully.");
