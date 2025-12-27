#!/bin/bash
# Intent Detection Pattern Library for ReAcTree Smart Detection
# Shared patterns used by detect-intent.sh

#==============================================================================
# FEATURE DEVELOPMENT PATTERNS
#==============================================================================

FEATURE_PATTERNS=(
  # Action verbs indicating new work
  'add|implement|build|create|develop|make|generate|set up|introduce'

  # Feature-specific language
  'new feature|feature request|user can|users should|ability to'

  # Rails-specific feature indicators
  'add .* to .*(model|controller|view|api|endpoint)'
  'implement .* (authentication|authorization|payment|notification|email|export|import)'
  'build .* (dashboard|admin|interface|page|form|wizard)'
  'create .* (service|component|job|worker|mailer|concern)'

  # Integration patterns
  'integrate|connect|hook up|wire up|link'

  # CRUD operations
  'crud|scaffold|resource|restful'
)

#==============================================================================
# DEBUGGING PATTERNS
#==============================================================================

DEBUG_PATTERNS=(
  # Problem indicators
  'fix|debug|troubleshoot|diagnose|investigate|resolve|repair'

  # Error states
  'error|bug|issue|problem|broken|not working|failing|fails'
  'crash|exception|unexpected|incorrect|wrong'

  # Behavioral issues
  'doesn.t work|isn.t working|stopped working|suddenly|used to work'
  'should be .* but|expected .* got|returning (nil|null|empty)'

  # Performance issues
  'slow|timeout|memory leak|n\+1|performance issue'

  # Specific error types
  'undefined method|no method error|argument error|type error'
  'routing error|record not found|validation failed'
  'rollback|transaction|deadlock|connection'
)

#==============================================================================
# REFACTORING PATTERNS
#==============================================================================

REFACTOR_PATTERNS=(
  # Refactoring verbs
  'refactor|restructure|reorganize|cleanup|clean up|improve|optimize'

  # Code quality indicators
  'code smell|duplication|dry|extract|inline|rename|move'
  'consolidate|simplify|decouple|separate|modularize'

  # Design patterns
  'pattern|concern|mixin|module|service object|form object|query object'

  # Technical debt
  'technical debt|legacy|outdated|deprecated|upgrade|modernize'

  # Architecture
  'architecture|design|structure|organization|convention'
)

#==============================================================================
# TDD/TEST-FIRST PATTERNS
#==============================================================================

TDD_PATTERNS=(
  # Test-first language
  'test.first|tdd|test.driven|write tests? first|red.green.refactor'

  # Coverage emphasis
  'with tests?|ensure coverage|comprehensive tests?|full coverage'

  # Spec-related
  'spec|rspec|acceptance|integration test|system test'

  # Quality indicators
  'quality|reliable|robust|well.tested|production.ready'
)

#==============================================================================
# UTILITY AGENT PATTERNS
#==============================================================================

FILE_FINDER_PATTERNS=(
  # File search
  'find .* file|find all .* files|where is .* file|locate .* file'
  'list .* files|show .* files|what files'

  # Directory exploration
  'what.s in .* directory|show .* folder|list .* directory'

  # File type searches
  'find .* models?|find .* controllers?|find .* services?'
  'find .* components?|find .* views?|find .* specs?'
)

CODE_LINE_FINDER_PATTERNS=(
  # Method/definition search
  'where is .* defined|find definition|go to definition'
  'where is .* method|find .* method|locate .* method'

  # Usage search
  'find .* usages|find all (calls|references|uses)'
  'who calls|what calls|where is .* used|where is .* called'

  # Line-specific
  'show line|find line|what.s on line'

  # Symbol search
  'find .* class|find .* module|find .* constant'
)

GIT_DIFF_PATTERNS=(
  # Diff requests
  'what changed|show changes|show diff|git diff'
  'diff from|diff between|compare .* to'

  # History requests
  'who changed|who modified|git blame|last modified'
  'commit history|recent commits|when was .* changed'

  # Branch comparison
  'difference between .* and|changes in .* branch'
  'what.s new in|changes since'
)

LOG_ANALYZER_PATTERNS=(
  # Log reading
  'show .* log|check .* log|read .* log|view .* log'
  'development.log|production.log|server log|rails log'

  # Error finding
  'errors? in .* log|log errors?|recent errors?'
  'exceptions? in log|failures? in log'

  # Request tracking
  'request .* log|show request|find request'

  # Performance
  'slow queries?|sql .* log|performance .* log'
)

#==============================================================================
# EXCLUSION PATTERNS (things that should NOT trigger workflow)
#==============================================================================

EXCLUSION_PATTERNS=(
  # Simple questions
  '^(what is|how does|why|explain|tell me about|show me|describe)'

  # Documentation/reference
  'documentation|docs|example|syntax|reference|tutorial'

  # Git operations (use built-in commands)
  '^(commit|push|pull|merge|branch|rebase)'

  # File operations without implementation
  '^(read|show|display|cat|head|tail)'

  # Claude Code meta commands
  '^/(help|clear|config|status|history|hooks|compact)'
)

#==============================================================================
# RAILS CONTEXT PATTERNS (to verify Rails project)
#==============================================================================

RAILS_KEYWORDS=(
  'model|controller|view|migration|activerecord|activejob|actioncable'
  'turbo|stimulus|hotwire|sidekiq|rspec|rails|ruby|gem|bundle|rake'
  'app/models|app/controllers|app/services|app/components'
  'config/routes|db/migrate|spec/'
)
