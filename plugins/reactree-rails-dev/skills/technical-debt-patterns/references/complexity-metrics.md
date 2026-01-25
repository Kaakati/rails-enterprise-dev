# Complexity Metrics Reference

Detailed guide to measuring and interpreting code complexity in Rails applications.

## Flog (ABC Complexity)

Flog measures Assignment, Branches, and Calls - weighted by complexity.

### Scoring System

Flog assigns points based on:
- **Assignments**: Variable assignments
- **Branches**: Conditionals, loops, method calls
- **Calls**: Especially operator calls, dynamic calls

**Weights**:
| Operation | Base Score |
|-----------|------------|
| Assignment | 1 |
| Branch (if/case) | 1 |
| Method call | 1 |
| Operator | 2 |
| Dynamic method | 5 |
| eval/instance_eval | 5+ |

### Thresholds

| Score | Rating | Interpretation | Action |
|-------|--------|----------------|--------|
| < 10 | Excellent | Simple, easy to understand | None needed |
| 10-20 | Good | Acceptable complexity | Monitor |
| 20-30 | Moderate | Consider simplifying | Review |
| 30-60 | High | Difficult to maintain | Plan refactor |
| 60-100 | Very High | Hard to test and change | Priority refactor |
| > 100 | Critical | Major maintenance burden | Immediate action |

### Running Flog

```bash
# Overall project score
flog -q app/

# Top 10 most complex methods
flog -q app/ | head -10

# Grouped by class
flog -q -g app/

# Single file analysis
flog -d app/services/payment_service.rb

# Score threshold check (exit 1 if any method > 60)
flog -q app/ | awk '$1 > 60 { print; exit 1 }'
```

### Interpreting Output

```
   127.3: PaymentService#process_payment     app/services/payment_service.rb:15-89
    89.4: User#calculate_metrics             app/models/user.rb:45-98
    67.2: OrdersController#create            app/controllers/orders_controller.rb:20-55
```

Format: `score: Class#method  file:line_range`

### High-Scoring Patterns

**Deeply nested conditionals** (High scorer):
```ruby
def process(data)
  if data.present?
    if data[:type] == 'a'
      if data[:valid]
        # ... more nesting
      end
    end
  end
end
```

**Multiple method chains** (High scorer):
```ruby
def complex_query
  User.joins(:orders)
      .where(active: true)
      .where('orders.created_at > ?', 30.days.ago)
      .group(:status)
      .having('COUNT(*) > 5')
      .select('users.*, COUNT(orders.id) as order_count')
      .order('order_count DESC')
end
```

---

## Cyclomatic Complexity

Measures the number of linearly independent paths through code.

### Calculation

```
M = E - N + 2P
```
Where:
- E = edges in control flow graph
- N = nodes in control flow graph
- P = connected components (usually 1)

**Simplified**: Count decision points + 1

| Element | Adds |
|---------|------|
| `if` | +1 |
| `elsif` | +1 |
| `unless` | +1 |
| `while` | +1 |
| `until` | +1 |
| `for` | +1 |
| `case when` | +1 per when |
| `&&` / `and` | +1 |
| `||` / `or` | +1 |
| `rescue` | +1 |
| ternary `?:` | +1 |

### Thresholds

| Complexity | Rating | Risk | Testability |
|------------|--------|------|-------------|
| 1-5 | Low | Minimal | Easy |
| 6-10 | Moderate | Manageable | Moderate |
| 11-20 | High | Significant | Difficult |
| 21-50 | Very High | Major | Very difficult |
| > 50 | Extreme | Severe | Nearly impossible |

### Example Analysis

```ruby
def process_payment(payment)             # Base: 1
  return false unless payment.valid?     # +1 (unless)

  case payment.type
  when 'credit_card'                     # +1 (when)
    if payment.amount > 1000             # +1 (if)
      require_additional_verification
    end
  when 'bank_transfer'                   # +1 (when)
    schedule_transfer(payment)
  when 'crypto'                          # +1 (when)
    process_crypto(payment)
  end

  if payment.recurring? && payment.active?  # +1 (if) +1 (&&)
    setup_subscription(payment)
  end

  true
rescue PaymentError => e                 # +1 (rescue)
  handle_error(e)
  false
end
# Total Cyclomatic Complexity: 10
```

### Automated Detection

```bash
# Using Rubocop
rubocop --only Metrics/CyclomaticComplexity app/

# Using flog (approximation)
flog -d app/services/ | grep -E "^\s+[0-9]+\.[0-9]+:"

# Custom script
ruby -e '
  ARGV.each do |file|
    content = File.read(file)
    complexity = 1 +
      content.scan(/\b(if|elsif|unless|while|until|for|when|rescue)\b/).size +
      content.scan(/(\&\&|\|\|)/).size
    puts "#{file}: #{complexity}" if complexity > 10
  end
' app/**/*.rb
```

---

## Cognitive Complexity

Measures how difficult code is for humans to understand (different from cyclomatic).

### Key Principles

1. **Nesting increases difficulty exponentially**
2. **Breaks in linear flow add complexity**
3. **Shorthand structures are less complex**

### Scoring Rules

| Element | Score |
|---------|-------|
| `if/else/elsif` | +1, +1 per nesting level |
| `switch/case` | +1 |
| `for/while/until` | +1, +1 per nesting level |
| `catch/rescue` | +1 |
| Sequence of `&&`/`||` | +1 (total, not each) |
| Recursion | +1 |
| Jump to label/goto | +1 |

**Nesting Penalty**: Each nesting level adds +1 to inner constructs.

### Example Comparison

**Low Cognitive Complexity**:
```ruby
def get_words(number)
  case number
  when 1 then 'one'
  when 2 then 'two'
  when 3 then 'three'
  else number.to_s
  end
end
# Cognitive: 1 (single case statement)
```

**High Cognitive Complexity**:
```ruby
def get_words(number)
  if number == 1        # +1
    'one'
  elsif number == 2     # +1
    'two'
  elsif number == 3     # +1
    'three'
  else
    number.to_s
  end
end
# Cognitive: 3 (multiple if/elsif)
```

**Very High (Nested)**:
```ruby
def process(data)
  if data.present?                    # +1
    data.each do |item|               # +1, +1 (nested)
      if item.valid?                  # +1, +2 (nested twice)
        if item.special?              # +1, +3 (nested thrice)
          handle_special(item)
        end
      end
    end
  end
end
# Cognitive: 10
```

### Thresholds

| Score | Rating | Recommended Action |
|-------|--------|-------------------|
| 0-5 | Good | Maintainable |
| 6-10 | Moderate | Consider simplifying |
| 11-15 | High | Should refactor |
| > 15 | Critical | Must refactor |

---

## Method Count Metrics

### Methods Per Class

| Count | Rating | Notes |
|-------|--------|-------|
| < 10 | Good | Focused responsibility |
| 10-20 | Acceptable | Monitor for growth |
| 20-30 | High | Consider extraction |
| > 30 | Critical | Split the class |

### Public Methods Ratio

```
Public/Total Methods Ratio
```

| Ratio | Rating |
|-------|--------|
| < 30% | Good encapsulation |
| 30-50% | Acceptable |
| > 50% | Consider encapsulation |

---

## Lines of Code Metrics

### Method LOC

| Lines | Rating | Action |
|-------|--------|--------|
| < 10 | Excellent | Ideal |
| 10-20 | Good | Acceptable |
| 20-30 | Moderate | Consider splitting |
| 30-50 | High | Should split |
| > 50 | Critical | Must split |

### Class LOC

| Lines | Rating | Action |
|-------|--------|--------|
| < 100 | Excellent | Well-focused |
| 100-200 | Good | Acceptable |
| 200-300 | Moderate | Monitor |
| 300-500 | High | Plan extraction |
| > 500 | Critical | Must split |

---

## Combined Analysis Script

```bash
#!/bin/bash
# complexity_report.sh - Comprehensive complexity analysis

echo "=== Complexity Analysis Report ==="
echo "Generated: $(date)"
echo ""

echo "## Flog Scores (Top 20)"
flog -q -g app/ 2>/dev/null | head -20

echo ""
echo "## Critical Methods (Flog > 60)"
flog -q app/ 2>/dev/null | awk '$1 > 60 { print }'

echo ""
echo "## Large Files (>200 lines)"
find app -name "*.rb" -exec wc -l {} \; | awk '$1 > 200 { print }' | sort -rn

echo ""
echo "## Rubocop Complexity Issues"
rubocop --only Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity \
  --format simple app/ 2>/dev/null | grep -v "no offenses"

echo ""
echo "## Method Count Per Model"
for file in app/models/*.rb; do
  count=$(grep -c "^[[:space:]]*def " "$file" 2>/dev/null)
  if [ "$count" -gt 15 ]; then
    echo "$(basename $file): $count methods"
  fi
done
```

---

## CI Integration

### Fail Build on High Complexity

```yaml
# .github/workflows/complexity.yml
name: Complexity Check

on: [push, pull_request]

jobs:
  complexity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1

      - name: Install flog
        run: gem install flog

      - name: Check complexity
        run: |
          THRESHOLD=60
          HIGH_COMPLEXITY=$(flog -q app/ | awk -v t=$THRESHOLD '$1 > t { count++ } END { print count+0 }')

          if [ "$HIGH_COMPLEXITY" -gt 0 ]; then
            echo "Found $HIGH_COMPLEXITY methods with Flog score > $THRESHOLD"
            flog -q app/ | awk -v t=$THRESHOLD '$1 > t { print }'
            exit 1
          fi

          echo "All methods below complexity threshold"
```
