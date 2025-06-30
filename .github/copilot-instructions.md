# PowerShell Coding Standards
- Always use approved PowerShell verbs for function names (get, set, new, start, remove, update, etc.)
- Use Pascal case for all function names, variables, and parameters
- Follow OTBS (One True Brace Style) formatting
- Include one blank line at the end of every script
- Remove all trailing spaces
- Use proper cmdlet binding and parameter validation
- Always include comment-based help for functions

# General Coding Guidelines
- Always add meaningful comments for complex logic
- Prefer explicit error handling over silent failures
- Include unit tests for all new functions

# Response Preferences
- Include brief explanations of why a particular approach is recommended
- When suggesting refactoring, explain the benefits
- Provide both the solution and alternative approaches when applicable

# Security Guidelines
- Never hardcode credentials or API keys
- Always validate input parameters
- Implement proper authentication and authorization checks

# PowerShell Commit Message Template

Generate commit messages for PowerShell projects using this format:

`<emoji><type>[optional scope]: <description>`

Follow the GitMoji specifications at <https://conventional-emoji-commits.site/full-specification/specification> for
commit messages. Tailor commit messages for PowerShell development, using the provided types and scopes.

### PowerShell-Specific Types:
- **feat**: ✨ New cmdlet, function, or module feature
- **fix**: 🐛 Bug fix in PowerShell code
- **docs**: 📚 Help documentation, comment-based help
- **style**: 🎨 Code formatting, OTBS compliance, Pascal case fixes
- **refactor**: ♻️ Code restructuring, approved verb compliance
- **test**: ✅ Pester tests, unit tests
- **build**: 🛠️ Module manifest, build scripts
- **ci**: 🤖 Azure DevOps, GitHub Actions for PowerShell
- **chore**: 🧹 Module organization, file cleanup
- **perf**: ⚡ Performance improvements in cmdlets or functions
- **revert**: ⏪ Reverting changes in PowerShell scripts or modules
- **packaging**: 📦 Packaging changes, module version updates
- **security**: 🔒 Security-related changes, input validation, authentication

### PowerShell Scopes:
- module: Module-level changes
- cmdlet: Specific cmdlet modifications
- function: Function updates
- help: Documentation changes
- manifest: Module manifest updates
- tests: Test-related changes

### Examples:
✨feat(cmdlet): add Get-UserProfile with parameter validation
🐛fix(function): resolve Invoke-ApiCall error handling
📚docs(help): update comment-based help for Set-Configuration
🎨style(module): apply OTBS formatting and Pascal case
✅test(cmdlet): add Pester tests for Get-SystemInfo
