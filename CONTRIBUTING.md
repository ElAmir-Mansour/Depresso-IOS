# Contributing to Depresso

First off, thank you for considering contributing to Depresso! It's people like you who make Depresso such a great tool for mental health support.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)

---

## 🤝 Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to make participation in our project and our community a harassment-free experience for everyone.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

---

## 🚀 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When filing a bug report, include:**
- Clear and descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if applicable
- Environment details:
  - iOS version
  - Xcode version
  - Device model
  - Backend server version

**Example:**
```markdown
**Bug**: AI chat not responding

**Steps to Reproduce:**
1. Open Journal tab
2. Send message "Hello"
3. Wait 30 seconds

**Expected:** AI responds
**Actual:** Timeout error

**Environment:**
- iOS 17.0
- iPhone 14 Pro
- Backend v1.0.0
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:
- Clear description of the enhancement
- Rationale for the feature
- Potential implementation approach
- Mockups or wireframes if applicable

### Contributing Code

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages**
6. **Push to your fork**
7. **Open a Pull Request**

---

## 🛠 Development Setup

### Prerequisites
- Xcode 15.0+
- Node.js 18+
- PostgreSQL 14+
- Git

### Local Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/Depresso-IOS.git
cd Depresso-IOS

# Add upstream remote
git remote add upstream https://github.com/ElAmir-Mansour/Depresso-IOS.git

# Setup backend
cd depresso-backend
npm install
createdb depresso_test
psql depresso_test < schema.sql
npm test

# Setup iOS
cd ..
open Depresso.xcodeproj
# Build and run tests (⌘U)
```

### Running Tests

**Backend:**
```bash
cd depresso-backend
npm test
npm run test:coverage
```

**iOS:**
- Open Xcode
- Press ⌘U to run all tests
- Or: Product → Test

---

## 📝 Coding Standards

### Swift Style Guide

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

**Key points:**
- Use descriptive names
- Prefer clarity over brevity
- Use camelCase for variables/functions
- Use PascalCase for types
- Add documentation comments for public APIs

**Example:**
```swift
/// Fetches health metrics for the specified date range
/// - Parameters:
///   - startDate: The beginning of the date range
///   - endDate: The end of the date range
/// - Returns: An array of health metrics
/// - Throws: `NetworkError` if the request fails
func fetchHealthMetrics(
    from startDate: Date,
    to endDate: Date
) async throws -> [HealthMetric] {
    // Implementation
}
```

### JavaScript/Node.js Style Guide

Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)

**Key points:**
- Use ES6+ features
- Prefer `const` over `let`
- Use async/await over callbacks
- Add JSDoc comments for functions
- Use meaningful variable names

**Example:**
```javascript
/**
 * Processes AI chat message and returns response
 * @param {string} message - User's message
 * @param {string} userId - User ID
 * @returns {Promise<string>} AI response
 */
async function processAIMessage(message, userId) {
    // Implementation
}
```

### Code Organization

**iOS:**
```
Features/
├── FeatureName/
│   ├── FeatureNameFeature.swift     # TCA Feature
│   ├── FeatureNameView.swift        # SwiftUI View
│   ├── Models/                      # Data models
│   └── Components/                  # Reusable components
```

**Backend:**
```
src/
├── routes/                          # API routes
├── middleware/                      # Express middleware
├── services/                        # Business logic
├── models/                          # Database models
└── utils/                           # Helper functions
```

---

## 📦 Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(dashboard): add weekly progress chart

Implemented interactive chart showing user's weekly mental health progress.
Includes data from PHQ-8 assessments and health metrics.

Closes #123
```

```bash
fix(journal): resolve AI response timeout

Increased timeout from 10s to 30s and added retry logic.
Added better error messages for timeout scenarios.

Fixes #456
```

```bash
docs(readme): update setup instructions

Added troubleshooting section for common installation issues.
Clarified Huawei Cloud configuration steps.
```

---

## 🔄 Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Test thoroughly**
   - Run all unit tests
   - Test on real device
   - Check for console errors
   - Verify backend endpoints

3. **Update documentation**
   - Update README if needed
   - Add/update code comments
   - Update API docs if applicable

4. **Check code quality**
   - SwiftLint (iOS): Fix all warnings
   - ESLint (Backend): `npm run lint`

### PR Template

When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Screenshots (if applicable)
Add screenshots or recordings

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] Added tests
- [ ] All tests passing
- [ ] No new warnings
```

### Review Process

1. Maintainers will review within 1-3 days
2. Address any requested changes
3. Once approved, maintainers will merge
4. Your contribution will be acknowledged!

---

## 🐛 Issue Guidelines

### Creating Issues

**Bug Report Template:**
```markdown
**Describe the bug**
Clear description of the bug

**To Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen

**Screenshots**
If applicable

**Environment**
- iOS version:
- Device:
- App version:
```

**Feature Request Template:**
```markdown
**Is your feature request related to a problem?**
Description

**Describe the solution**
What you want to happen

**Describe alternatives**
Alternative solutions considered

**Additional context**
Any other information
```

### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `question`: Further information requested
- `wontfix`: Not planned

---

## 🎯 Areas for Contribution

### High Priority

- 🐛 Bug fixes
- 📝 Documentation improvements
- ♿️ Accessibility enhancements
- 🌐 Internationalization

### Feature Requests

- Apple Watch companion app
- Enhanced AI models
- Advanced analytics
- Therapist connection feature

### Good First Issues

Look for issues labeled `good first issue` - these are perfect for first-time contributors!

---

## 💡 Tips for Success

1. **Start small**: Begin with documentation or small bug fixes
2. **Ask questions**: Don't hesitate to ask for clarification
3. **Be patient**: Reviews take time
4. **Be respectful**: We're all here to help
5. **Have fun**: Enjoy contributing!

---

## 🏆 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Acknowledged in the README

---

## 📞 Getting Help

- 💬 [Join Discussions](https://github.com/ElAmir-Mansour/Depresso-IOS/discussions)
- 📧 Email: [your-email@example.com]
- 🐛 [Report Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Depresso! Together, we're making mental health support more accessible. 💙**
