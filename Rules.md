# 🛠️ **Prompt Engineering Guide for AI-Powered Software Development**

This document outlines structured prompts designed specifically to streamline AI collaboration for software project ideation, validation, planning, and pair programming.

## 🚩 **Prompt List**

### ✅ **1. Idea Validation and Challenge**

**Trigger:** `  /challenge [brief idea description]   `

**Purpose:**

Validate, critique, and analyze the feasibility and market potential of your software idea.

**AI Response Guidelines:**

* Summarize and restate clearly.
* Constructive critique (pros & cons).
* Analyze market potential, competitors, niche opportunities, and technical feasibility.
* Estimate complexity, potential costs, and expected challenges.
* Consider feasibility with the main developers (you and AI).

**Example:** `  /challenge An AI-driven VSCode extension that suggests context-aware code snippets.   `

### ✅ **2. Statement of Requirements (SOR)**

**Trigger:** `  /generate-sor [confirmed idea name]   `

**Purpose:**

Generate a clear and detailed scope of the project.

**AI Response Guidelines:**

* Define application objective.
* List core features and functionalities.
* Specify user interactions, workflows, and UX considerations.
* Detail technical constraints or integrations.
* Provide acceptance criteria for each feature.

**Example:** `  /generate-sor SnipVault AI snippet manager.   `

### ✅ **3. Project Plan, Milestones, and Releases**

**Trigger:** `  /generate-plan   `

**Purpose:**

Create an organized project roadmap, including milestones, MVP definition, and release phases.

**AI Response Guidelines:**

* Outline phased approach with clear milestones.
* Define MVP and subsequent release phases.
* Provide estimated timelines or effort indicators.
* Specify deliverables clearly.

### ✅ **4. Infrastructure and Tech Stack Decision**

**Trigger:** `  /decide-stack   `

**Purpose:**

Determine and justify optimal technology choices and infrastructure setup.

**AI Response Guidelines:**

* Recommend frontend, backend, databases, services, infrastructure providers, and deployment platforms.
* Provide rationale based on requirements, scalability, performance, maintainability, and developer experience.
* Suggest optional alternatives briefly.

### ✅ **5. Comprehensive Project Documentation (Markdown)**

**Trigger:** `  /document-project   `

**Purpose:**

Produce a concise Markdown summary of steps 1-4.

**AI Response Guidelines:**

* Summarize the project idea, validation, and market analysis.
* Include the SOR clearly outlined.
* Detail project plan, milestones, and release phases.
* Include infrastructure and tech stack decisions.

### ✅ **6. Interactive Pair Programming**

**Trigger:** `  /pair [description of current task]   `

**Purpose:**

Collaborate directly with AI in coding tasks and implementations.

**AI Response Guidelines:**

* Provide explicit, runnable code snippets (no placeholders).
* Walk through implementations step-by-step.
* Use latest stable versions of chosen technologies.
* Avoid zip files or canvas usage unless explicitly requested.

**Example:** `  /pair Set up Lucia for passwordless email authentication.   `

### ✅ **7. Progression Prompt**

**Trigger:** `  /next   `

**Purpose:**

Clearly identify the next action based on the established plan.

**AI Response Guidelines:**

* Prompt the next step strictly according to the project plan.
* Reference provided Markdown document section.
* Prevent deviations from established features, stack, or scope.

### ✅ **8. App Concept Definition** *(Newly Added)*

**Trigger:** `  /define-app [tech/framework] [purpose/goal] consider:[factors to consider] exclude:[factors to exclude]   `

**Purpose:**

Clearly define and refine the initial concept of the app including technological choices, targeted outcomes, and scope boundaries.

**AI Response Guidelines:**

* Clearly outline the technological framework or language specified.
* Precisely define the purpose, goals, and expected outcomes of the application.
* Explicitly consider specified important factors (such as scalability, performance, ease of use, or specific integrations).
* Explicitly exclude certain elements or constraints as requested to maintain project focus and scope.

**Example:** `  /define-app using SvelteKit that serves the purpose of task management for remote teams. consider:real-time updates, simplicity exclude:complex permissions systems.   `
