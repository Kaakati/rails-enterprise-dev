---
name: reactree-feature
description: ReAcTree-based feature development with user stories, parallel execution, and memory systems
allowed-tools: ["*"]
---

# ReAcTree Feature Development

Feature-specific workflow emphasizing:
- User story definition
- Acceptance criteria
- Test-driven development
- Component-based architecture

## Usage

```
/rails-feature [feature description]
```

## Examples

```
/rails-feature User can export tasks to CSV
/rails-feature Admin dashboard shows real-time metrics
/rails-feature Multi-language support with Arabic RTL
```

## Workflow

Same as `/rails-dev` but emphasizes:
1. **Feature Definition** - Clear user stories with acceptance criteria
2. **Skill Usage** - `requirements-writing` skill (if available)
3. **TDD Cycle** - Write tests first approach
4. **Integration** - Ensure feature integrates with existing system

## Activation

```
{{TASK_REQUEST}}

Please activate the Rails Feature Development workflow:
1. If requirements-writing skill available, invoke it for user story structure
2. Define clear acceptance criteria
3. Execute standard workflow with TDD emphasis
4. Validate against acceptance criteria in review phase

Start the workflow with feature definition.
```

---

For more details, see `/rails-dev` documentation.
