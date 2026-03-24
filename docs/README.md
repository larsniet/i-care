# EyeCare MVP Documentation

This folder turns the original idea into a buildable MVP plan for a native Apple app.

## Source

- `docs/business_idea.md`: original brainstorming and product rationale

## Product

- `docs/product/product_brief.md`: problem, positioning, users, principles, and product promise
- `docs/product/mvp_spec.md`: MVP requirements, non-goals, feature scope, and release boundaries
- `docs/product/user_flows.md`: core user journeys for iPhone and Apple Watch

## Technical

- `docs/technical/architecture.md`: proposed native architecture, modules, notification strategy, and platform design
- `docs/technical/data_model.md`: app state, storage model, and domain entities
- `docs/technical/notification_strategy.md`: local notification rules, failure modes, and platform behavior guidance

## Delivery

- `docs/delivery/implementation_plan.md`: milestone-based build plan and recommended work order
- `docs/delivery/acceptance_criteria.md`: release gates, QA scenarios, and MVP success criteria

## Recommended Build Order

1. Align on `product_brief.md` and `mvp_spec.md`.
2. Lock the technical decisions in `architecture.md` and `data_model.md`.
3. Build the flows in the order listed in `implementation_plan.md`.
4. Ship only when `acceptance_criteria.md` is satisfied.
