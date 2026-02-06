# 🔐 Authentication Security Plan

## Overview
Secure authentication system for Dynamic Artist Monetization Platform using JWT tokens, bcrypt password hashing, and email-based password recovery.

---

## 🗄️ Database Schema

### Users Collection (Already Created - Enhanced)

```typescript
{
  _id: ObjectId,
  email: String (unique, required, lowercase, validated),
  password: String (hashed with bcrypt, select: false),
  username: String (unique, optional, 3-30 chars),
  role: Enum ['artist', 'fan', 'admin'] (default: 'fan'),
  tokens: Number (default: 0, min: 0),
  
  // Profile
  avatar: String (URL),
  bio: String (max 500 chars),
  
  // Email Verification
  isVerified: Boolean (default: false),
  emailVerificationToken: String (hashed),
  emailVerificationExpire: Date,
  
  // Password Reset
  resetPasswordToken: String (hashed),
  resetPasswordExpire: Date (15 minutes TTL),
  
  // Security
  lastLogin: Date,
  loginAttempts: Number (default: 0),
  lockUntil: Date (account lock for failed attempts),
  
  // Refresh Token (Alternative: separate collection)
  refreshToken: String (hashed),
  refreshTokenExpire: Date,
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

### Optional: RefreshTokens Collection (Recommended for better security)

```typescript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  token: String (hashed),
  expiresAt: Date,
  createdAt: Date,
  
  // Device tracking (optional)
  userAgent: String,
  ipAddress: String,
  deviceId: String
}
```

### Indexes
```javascript
users.email: unique
users.username: unique, sparse
users.resetPasswordToken: 1
users.emailVerificationToken: 1
users.refreshToken: 1

refreshTokens.userId: 1
refreshTokens.token: 1
refreshTokens.expiresAt: 1 (TTL index)
```

---

## 🔒 Security Architecture

### 1. Password Security

**Hashing Strategy:**
```
- Algorithm: bcrypt
- Salt Rounds: 10 (2^10 iterations)
- Pre-save hook: Hash password before saving to DB
- Never return password in API responses
```

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character
- No common passwords (use validator library)

**Implementation:**
```typescript
// Password validation regex
const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

// Bcrypt hashing
import bcrypt from 'bcryptjs';
const hashedPassword = await bcrypt.hash(password, 10);

// Password comparison
const isMatch = await bcrypt.compare(candidatePassword, hashedPassword);
```

---

### 2. JWT Token Strategy

**Two-Token System (Access + Refresh)**

#### Access Token
```javascript
{
  payload: {
    userId: user._id,
    email: user.email,
    role: user.role
  },
  secret: JWT_SECRET (from env),
  expiresIn: '15m' (short-lived),
  algorithm: 'HS256'
}
```

#### Refresh Token
```javascript
{
  payload: {
    userId: user._id,
    tokenVersion: user.tokenVersion // for invalidation
  },
  secret: JWT_REFRESH_SECRET (different from access),
  expiresIn: '7d' (long-lived),
  algorithm: 'HS256'
}
```

**Token Storage:**
- **Access Token**: Client-side (memory/state) - NOT localStorage
- **Refresh Token**: HttpOnly cookie (secure, sameSite: strict)
- **Alternative**: Secure localStorage with encryption (web only)

**Token Flow:**
```
1. Login → Return access token + refresh token
2. Client stores access token in memory
3. Refresh token stored in httpOnly cookie
4. Access token expires → Use refresh token to get new access token
5. Refresh token expires → User must login again
```

---

### 3. Rate Limiting & Brute Force Protection

**Failed Login Attempts:**
```javascript
- Max Attempts: 5 failed logins
- Lock Duration: 15 minutes
- Counter Reset: On successful login
- Implementation: Store in User model (loginAttempts, lockUntil)
```

**Rate Limiting (Already configured):**
```javascript
- Window: 15 minutes
- Max Requests: 100 per IP
- Auth Endpoints: Stricter limits (5 login attempts per 15 min)
```

**Implementation Strategy:**
```typescript
// Check if account is locked
if (user.lockUntil && user.lockUntil > Date.now()) {
  throw new Error('Account locked. Try again later.');
}

// Increment failed attempts
if (passwordIncorrect) {
  user.loginAttempts += 1;
  
  if (user.loginAttempts >= 5) {
    user.lockUntil = Date.now() + 15 * 60 * 1000; // 15 minutes
  }
  
  await user.save();
}

// Reset on success
user.loginAttempts = 0;
user.lockUntil = undefined;
```

---

## 🔄 Authentication Flows

### 1. Registration Flow

```
Client                          Server                      Database
  |                               |                             |
  |-- POST /api/v1/auth/register -|                             |
  |    { email, password, role }  |                             |
  |                               |                             |
  |                               |-- Validate input            |
  |                               |-- Check email exists        |
  |                               |                          ---| Query users
  |                               |                          <--|
  |                               |-- Hash password (bcrypt)    |
  |                               |-- Generate verification token|
  |                               |-- Create user            ---| Insert
  |                               |                          <--|
  |                               |-- Send verification email   |
  |                               |-- Generate JWT tokens       |
  |                               |                             |
  |<-- 201 { user, accessToken } -|                             |
  |    Set-Cookie: refreshToken   |                             |
  |                               |                             |
  |-- Verify email link          -|                             |
  |                               |-- Validate token            |
  |                               |-- Mark user verified     ---| Update
  |<-- 200 { verified: true }    -|                          <--|
```

**Security Considerations:**
- Email must be unique
- Password hashed before storage
- Email verification token expires in 24 hours
- Verification token is hashed in database
- Send welcome email after verification

---

### 2. Login Flow

```
Client                          Server                      Database
  |                               |                             |
  |-- POST /api/v1/auth/login ------|                             |
  |    { email, password }        |                             |
  |                               |                             |
  |                               |-- Validate input            |
  |                               |-- Find user (with password) -| Query
  |                               |                          <--|
  |                               |-- Check account lock        |
  |                               |-- Compare password (bcrypt) |
  |                               |                             |
  |                       [If Invalid Password]                 |
  |                               |-- Increment loginAttempts   |
  |                               |-- Lock if >= 5 attempts  ---| Update
  |<-- 401 { error }            -|                          <--|
  |                               |                             |
  |                       [If Valid Password]                   |
  |                               |-- Reset loginAttempts       |
  |                               |-- Update lastLogin       ---| Update
  |                               |-- Generate JWT tokens    <--|
  |                               |                             |
  |<-- 200 { user, accessToken } -|                             |
  |    Set-Cookie: refreshToken   |                             |
```

**Security Considerations:**
- Select password field explicitly (normally hidden)
- Check account lock before password comparison
- Constant-time password comparison (bcrypt handles this)
- Log failed attempts
- Update lastLogin timestamp
- Return generic error message (don't reveal if email exists)

---

### 3. Refresh Token Flow

```
Client                          Server                      Database
  |                               |                             |
  |-- POST /api/v1/auth/refresh --|                             |
  |    Cookie: refreshToken       |                             |
  |                               |                             |
  |                               |-- Extract refresh token     |
  |                               |-- Verify JWT signature      |
  |                               |-- Check token expiry        |
  |                               |-- Validate user exists   ---| Query
  |                               |                          <--|
  |                               |-- Generate new access token |
  |                               |                             |
  |<-- 200 { accessToken }       -|                             |
  |    (Optional: rotate refresh token)                         |
```

**Security Considerations:**
- Verify refresh token signature
- Check user still exists and active
- Optional: Rotate refresh token on use (reuse detection)
- Blacklist old refresh tokens (optional, requires Redis)

---

### 4. Forgot Password Flow

```
Client                          Server                      Database        Email Service
  |                               |                             |                  |
  |-- POST /api/v1/auth/forgot-password                         |                  |
  |    { email }                  |                             |                  |
  |                               |                             |                  |
  |                               |-- Validate email format     |                  |
  |                               |-- Find user by email     ---| Query            |
  |                               |                          <--|                  |
  |                               |-- Generate reset token      |                  |
  |                               |   (crypto.randomBytes)      |                  |
  |                               |-- Hash token (SHA256)       |                  |
  |                               |-- Save hashed token      ---| Update           |
  |                               |   + expiry (15 min)      <--|                  |
  |                               |-- Send reset email ---------|----------------->|
  |<-- 200 { message }           -|                             |                  |
  |                               |                             |                  |
  |-- Click email link -----------|                             |                  |
  |                               |                             |                  |
  |-- GET /reset-password/:token -|                             |                  |
  |                               |-- Hash received token       |                  |
  |                               |-- Find user by token     ---| Query            |
  |                               |   + check expiry         <--|                  |
  |<-- 200 { valid: true }       -|                             |                  |
  |                               |                             |                  |
  |-- POST /api/v1/auth/reset-password                          |                  |
  |    { token, newPassword }     |                             |                  |
  |                               |-- Validate token + expiry   |                  |
  |                               |-- Hash new password         |                  |
  |                               |-- Update password        ---| Update           |
  |                               |-- Clear reset token      <--|                  |
  |                               |-- Invalidate all sessions   |                  |
  |<-- 200 { message }           -|                             |                  |
```

**Security Considerations:**
- Use crypto.randomBytes(32) for token generation
- Hash token before storing (SHA256)
- Token expires in 15 minutes
- One-time use token (delete after use)
- Don't reveal if email exists (same response)
- Invalidate all existing sessions after reset
- Send confirmation email after password change

---

### 5. Logout Flow

```
Client                          Server                      Database
  |                               |                             |
  |-- POST /api/v1/auth/logout --|                             |
  |    Authorization: Bearer token|                             |
  |    Cookie: refreshToken       |                             |
  |                               |                             |
  |                               |-- Verify access token       |
  |                               |-- Clear refresh token    ---| Update/Delete
  |                               |   from database          <--|
  |                               |-- Clear cookie              |
  |                               |                             |
  |<-- 200 { message }           -|                             |
  |    Set-Cookie: refreshToken=; expires=past                  |
  |                               |                             |
  |-- Clear access token from memory                            |
```

**Security Considerations:**
- Invalidate refresh token in database
- Clear httpOnly cookie
- Client must clear access token from memory
- Optional: Maintain token blacklist (Redis) until expiry

---

## 🛡️ Security Best Practices

### 1. Input Validation

```typescript
import Joi from 'joi';

// Registration validation
const registerSchema = Joi.object({
  email: Joi.string().email().required().lowercase().trim(),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/)
    .required()
    .messages({
      'string.pattern.base': 'Password must contain uppercase, lowercase, number and special character'
    }),
  username: Joi.string().min(3).max(30).alphanum().trim(),
  role: Joi.string().valid('artist', 'fan').default('fan')
});

// Login validation
const loginSchema = Joi.object({
  email: Joi.string().email().required().lowercase().trim(),
  password: Joi.string().required()
});

// Forgot password validation
const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required().lowercase().trim()
});

// Reset password validation
const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/)
    .required()
});
```

---

### 2. Environment Variables

```env
# JWT Configuration
JWT_SECRET=very-long-random-string-min-32-chars-use-crypto-randomBytes
JWT_EXPIRE=15m
JWT_REFRESH_SECRET=different-very-long-random-string-min-32-chars
JWT_REFRESH_EXPIRE=7d

# Cookie Configuration
COOKIE_SECRET=another-random-string-for-cookie-signing
COOKIE_DOMAIN=yourdomain.com
COOKIE_SECURE=true  # true in production (HTTPS only)
COOKIE_SAMESITE=strict

# Password Reset
RESET_PASSWORD_EXPIRE=15  # minutes

# Email Verification
EMAIL_VERIFICATION_EXPIRE=24  # hours

# Account Lock
MAX_LOGIN_ATTEMPTS=5
LOCK_DURATION=15  # minutes

# Email Service (SendGrid/AWS SES/Mailgun)
EMAIL_SERVICE=sendgrid
EMAIL_API_KEY=your-api-key
EMAIL_FROM=noreply@yourdomain.com
EMAIL_FROM_NAME=Dynamic Artist Platform
```

---

### 3. Middleware Structure

```typescript
// 1. Authentication Middleware
export const protect = async (req, res, next) => {
  // Extract token from header
  // Verify JWT signature
  // Check token expiry
  // Attach user to request
  // Call next()
};

// 2. Role-based Authorization
export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    next();
  };
};

// 3. Optional Authentication (for public endpoints)
export const optionalAuth = async (req, res, next) => {
  // Try to authenticate but don't fail if token missing
  // Useful for endpoints that work for both auth/non-auth users
};

// 4. Email Verification Check
export const requireVerified = (req, res, next) => {
  if (!req.user.isVerified) {
    return res.status(403).json({ 
      error: 'Email verification required' 
    });
  }
  next();
};
```

---

### 4. Token Generation Utilities

```typescript
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

// Generate Access Token
export const generateAccessToken = (userId: string, email: string, role: string) => {
  return jwt.sign(
    { userId, email, role },
    process.env.JWT_SECRET!,
    { expiresIn: process.env.JWT_EXPIRE || '15m' }
  );
};

// Generate Refresh Token
export const generateRefreshToken = (userId: string) => {
  return jwt.sign(
    { userId },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: process.env.JWT_REFRESH_EXPIRE || '7d' }
  );
};

// Generate Password Reset Token
export const generateResetToken = () => {
  const resetToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');
  
  return { resetToken, hashedToken };
};

// Verify Access Token
export const verifyAccessToken = (token: string) => {
  return jwt.verify(token, process.env.JWT_SECRET!);
};

// Verify Refresh Token
export const verifyRefreshToken = (token: string) => {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET!);
};
```

---

### 5. Error Handling

```typescript
// Custom error class
export class AuthError extends Error {
  statusCode: number;
  
  constructor(message: string, statusCode: number = 401) {
    super(message);
    this.statusCode = statusCode;
  }
}

// Common auth errors
export const AuthErrors = {
  INVALID_CREDENTIALS: new AuthError('Invalid credentials', 401),
  ACCOUNT_LOCKED: new AuthError('Account locked due to multiple failed attempts', 423),
  TOKEN_EXPIRED: new AuthError('Token expired', 401),
  TOKEN_INVALID: new AuthError('Invalid token', 401),
  EMAIL_NOT_VERIFIED: new AuthError('Email not verified', 403),
  UNAUTHORIZED: new AuthError('Not authorized', 401),
  FORBIDDEN: new AuthError('Forbidden', 403),
  USER_EXISTS: new AuthError('User already exists', 409),
  USER_NOT_FOUND: new AuthError('User not found', 404),
  WEAK_PASSWORD: new AuthError('Password does not meet requirements', 400)
};
```

---

## 📧 Email Templates (Required)

### 1. Welcome Email (After Registration)
```
Subject: Welcome to Dynamic Artist Monetization!

Hi [Username],

Welcome! Your account has been created successfully.

Please verify your email: [Verification Link]

Link expires in 24 hours.
```

### 2. Email Verification
```
Subject: Verify Your Email Address

Hi [Username],

Click the link below to verify your email:
[Verification Link]

This link expires in 24 hours.
```

### 3. Password Reset
```
Subject: Reset Your Password

Hi [Username],

You requested a password reset. Click the link below:
[Reset Link]

This link expires in 15 minutes.

If you didn't request this, please ignore this email.
```

### 4. Password Changed Confirmation
```
Subject: Password Changed Successfully

Hi [Username],

Your password was changed successfully.

If this wasn't you, contact support immediately.
```

---

## 🧪 Testing Checklist

### Registration
- [ ] Valid registration creates user
- [ ] Duplicate email rejected
- [ ] Weak password rejected
- [ ] Email verification sent
- [ ] Invalid email format rejected
- [ ] SQL injection attempts blocked

### Login
- [ ] Valid credentials return tokens
- [ ] Invalid email rejected
- [ ] Invalid password rejected
- [ ] Account locked after 5 failed attempts
- [ ] Lock expires after 15 minutes
- [ ] Successful login resets attempts

### Token Management
- [ ] Access token expires after 15 minutes
- [ ] Refresh token works before expiry
- [ ] Expired refresh token rejected
- [ ] Invalid token signature rejected
- [ ] Token for deleted user rejected

### Password Reset
- [ ] Reset email sent for valid email
- [ ] Same response for invalid email (security)
- [ ] Token expires after 15 minutes
- [ ] Token is one-time use
- [ ] Password requirements enforced
- [ ] All sessions invalidated after reset

### Email Verification
- [ ] Verification link works
- [ ] Expired token rejected
- [ ] Already verified user handled
- [ ] Invalid token rejected

---

## 🔐 Security Audit Points

1. **Passwords**
   - [ ] Never logged or exposed in API
   - [ ] Bcrypt with salt rounds >= 10
   - [ ] Strong password requirements enforced
   - [ ] No password hints or security questions

2. **Tokens**
   - [ ] Strong secret keys (>= 32 chars random)
   - [ ] Short-lived access tokens (<= 15 min)
   - [ ] Refresh tokens properly invalidated
   - [ ] Token rotation implemented

3. **Rate Limiting**
   - [ ] Strict limits on auth endpoints
   - [ ] Account lockout after failed attempts
   - [ ] IP-based rate limiting

4. **Data Protection**
   - [ ] HTTPS only in production
   - [ ] HttpOnly cookies for refresh tokens
   - [ ] SameSite cookie attribute
   - [ ] No sensitive data in JWT payload

5. **Database**
   - [ ] MongoDB injection protection (sanitization)
   - [ ] Indexed sensitive fields
   - [ ] Password field never selected by default

---

## 📱 Flutter Frontend Integration

### API Service Layer
```dart
class AuthService {
  Future<User> register(String email, String password, String role);
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<String> refreshToken();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> verifyEmail(String token);
}
```

### Token Storage
```dart
// Use flutter_secure_storage for tokens
final storage = FlutterSecureStorage();

// Store access token
await storage.write(key: 'accessToken', value: token);

// Retrieve token
final token = await storage.read(key: 'accessToken');

// Delete token
await storage.delete(key: 'accessToken');
```

### State Management
```dart
// User authentication state
class AuthState {
  final User? user;
  final String? accessToken;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
}
```

---

## ✅ Implementation Priority

### Phase 1: Core Authentication (Week 1)
1. User model enhancement (add security fields)
2. JWT utilities
3. Password hashing utilities
4. Registration endpoint
5. Login endpoint
6. Logout endpoint

### Phase 2: Token Management (Week 1)
7. Refresh token endpoint
8. Authentication middleware
9. Authorization middleware
10. Token expiry handling

### Phase 3: Password Recovery (Week 2)
11. Forgot password endpoint
12. Reset password endpoint
13. Email service integration
14. Email templates

### Phase 4: Email Verification (Week 2)
15. Email verification endpoint
16. Verification email sending
17. Account verification flow

### Phase 5: Flutter Integration (Week 3)
18. Auth service layer
19. Login/Register screens
20. Token storage
21. Auto-refresh logic
22. Protected routes

---

## 🎯 Success Criteria

- ✅ Secure password storage (bcrypt)
- ✅ JWT-based authentication
- ✅ Token refresh mechanism
- ✅ Rate limiting & brute force protection
- ✅ Password reset via email
- ✅ Email verification
- ✅ Account lockout mechanism
- ✅ Input validation
- ✅ Error handling
- ✅ Comprehensive testing

---

**Ready for implementation?** Let me know if you want to proceed or need any modifications to this plan!
