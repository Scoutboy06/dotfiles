# Mermaid classDiagram reference

Use this reference when you need exact syntax, relationship arrows, or edge cases.

## Minimal template

```mermaid
classDiagram
  class ClassName
```

## Class blocks

```mermaid
classDiagram
  class Order {
    +String id
    +Date placedAt
    +addItem(item)
  }
```

## Visibility modifiers

- `+` public
- `-` private
- `#` protected
- `~` package

## Relationships

- **Inheritance**: `Child --|> Parent`
- **Realization (interface)**: `Impl ..|> Interface`
- **Association**: `A --> B`
- **Dependency**: `A ..> B`
- **Aggregation**: `Whole o-- Part`
- **Composition**: `Whole *-- Part`

## Cardinality labels

Place quoted multiplicities near the ends:

```mermaid
classDiagram
  Customer "1" --> "*" Order
  Team "0..1" o-- "1" Lead
```

## Names, generics, and namespaces

- Use ASCII names unless the user specifies otherwise.
- Generics: `Class~T~`
- Namespaces: `namespace Foo { class Bar }`

## Interfaces and annotations

```mermaid
classDiagram
  class Shape {
    <<interface>>
    +area()
  }
  class Circle
  Circle ..|> Shape
```

```mermaid
classDiagram
  class Service {
    <<abstract>>
  }
```

## Notes and comments

- Notes: `note for ClassName "text"`
- Comments: `%% this is a comment`

## Common mistakes

- Missing `classDiagram` header.
- Unquoted cardinalities.
- Mixing up `--|>` vs `..|>`.
- Putting attributes/methods outside the class block.
