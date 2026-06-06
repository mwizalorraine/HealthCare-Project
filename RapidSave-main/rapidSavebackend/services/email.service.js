const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host:   process.env.MAIL_HOST,
  port:   parseInt(process.env.MAIL_PORT),
  secure: false,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

const baseTemplate = (content) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#1B3A6B 0%,#2563EB 100%);padding:36px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:700;letter-spacing:-0.5px;">RapidSave</h1>
              <p style="margin:6px 0 0;color:#BFDBFE;font-size:13px;">Medicine Access Platform</p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px;">
              ${content}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#F8FAFC;padding:24px 40px;border-top:1px solid #E2E8F0;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:12px;">© ${new Date().getFullYear()} RapidSave · Kigali, Rwanda</p>
              <p style="margin:6px 0 0;color:#94A3B8;font-size:12px;">If you did not request this email, please ignore it.</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

const sendEmail = async ({ to, subject, html }) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to,
    subject,
    html,
  });
};

const sendVerificationEmail = async (user, code) => {
  await sendEmail({
    to:      user.email,
    subject: 'RapidSave — Verify Your Email',
    html: baseTemplate(`
      <h2 style="margin:0 0 8px;color:#1B3A6B;font-size:22px;font-weight:700;">Verify Your Email</h2>
      <p style="margin:0 0 24px;color:#64748B;font-size:15px;">Hello <strong style="color:#1E293B;">${user.name}</strong>, welcome to RapidSave! Use the code below to verify your email address.</p>

      <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:12px;padding:32px;text-align:center;margin:0 0 24px;">
        <p style="margin:0 0 8px;color:#3B82F6;font-size:12px;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;">Verification Code</p>
        <p style="margin:0;color:#1B3A6B;font-size:42px;font-weight:700;letter-spacing:12px;">${code}</p>
        <p style="margin:12px 0 0;color:#94A3B8;font-size:12px;">Expires in <strong>15 minutes</strong></p>
      </div>

      <div style="background:#FEF3C7;border-left:4px solid #F59E0B;border-radius:0 8px 8px 0;padding:14px 16px;margin:0 0 24px;">
        <p style="margin:0;color:#92400E;font-size:13px;">Never share this code with anyone. RapidSave will never ask for your code.</p>
      </div>

      <p style="margin:0;color:#94A3B8;font-size:13px;">— The RapidSave Team</p>
    `),
  });
};

const sendWelcomeEmail = async (user) => {
  await sendEmail({
    to:      user.email,
    subject: 'Welcome to RapidSave — You\'re all set!',
    html: baseTemplate(`
      <h2 style="margin:0 0 8px;color:#1B3A6B;font-size:22px;font-weight:700;">You're all set!</h2>
      <p style="margin:0 0 24px;color:#64748B;font-size:15px;">Hello <strong style="color:#1E293B;">${user.name}</strong>, your email has been verified and your account is ready.</p>

      <div style="background:#F0FDF4;border:1px solid #BBF7D0;border-radius:12px;padding:24px;margin:0 0 24px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding:6px 0;">
              <span style="display:inline-block;width:8px;height:8px;background:#22C55E;border-radius:50%;margin-right:10px;vertical-align:middle;"></span>
              <span style="color:#166534;font-size:14px;">Search medicines across pharmacies in real time</span>
            </td>
          </tr>
          <tr>
            <td style="padding:6px 0;">
              <span style="display:inline-block;width:8px;height:8px;background:#22C55E;border-radius:50%;margin-right:10px;vertical-align:middle;"></span>
              <span style="color:#166534;font-size:14px;">Find nearby pharmacies using your location</span>
            </td>
          </tr>
          <tr>
            <td style="padding:6px 0;">
              <span style="display:inline-block;width:8px;height:8px;background:#22C55E;border-radius:50%;margin-right:10px;vertical-align:middle;"></span>
              <span style="color:#166534;font-size:14px;">Reserve or request delivery of your medicines</span>
            </td>
          </tr>
          <tr>
            <td style="padding:6px 0;">
              <span style="display:inline-block;width:8px;height:8px;background:#22C55E;border-radius:50%;margin-right:10px;vertical-align:middle;"></span>
              <span style="color:#166534;font-size:14px;">Track your delivery in real time</span>
            </td>
          </tr>
        </table>
      </div>

      <p style="margin:0;color:#94A3B8;font-size:13px;">— The RapidSave Team</p>
    `),
  });
};

const sendPasswordResetEmail = async (user, resetToken) => {
  await sendEmail({
    to:      user.email,
    subject: 'RapidSave — Password Reset Request',
    html: baseTemplate(`
      <h2 style="margin:0 0 8px;color:#1B3A6B;font-size:22px;font-weight:700;">Reset Your Password</h2>
      <p style="margin:0 0 24px;color:#64748B;font-size:15px;">Hello <strong style="color:#1E293B;">${user.name}</strong>, we received a request to reset your RapidSave password.</p>

      <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:12px;padding:32px;text-align:center;margin:0 0 24px;">
        <p style="margin:0 0 8px;color:#3B82F6;font-size:12px;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;">Reset Token</p>
        <p style="margin:0;color:#1B3A6B;font-size:32px;font-weight:700;letter-spacing:8px;">${resetToken}</p>
        <p style="margin:12px 0 0;color:#94A3B8;font-size:12px;">Expires in <strong>15 minutes</strong></p>
      </div>

      <div style="background:#FEF3C7;border-left:4px solid #F59E0B;border-radius:0 8px 8px 0;padding:14px 16px;margin:0 0 24px;">
        <p style="margin:0;color:#92400E;font-size:13px;">If you did not request a password reset, please secure your account immediately.</p>
      </div>

      <p style="margin:0;color:#94A3B8;font-size:13px;">— The RapidSave Team</p>
    `),
  });
};

const sendOrderStatusEmail = async (user, order, status) => {
  const statusConfig = {
    confirmed: { color: '#0F766E', bg: '#F0FDF9', border: '#99F6E4', icon: '✓', label: 'Confirmed',  message: 'Your order has been confirmed by the pharmacy and is being prepared.' },
    ready:     { color: '#1D4ED8', bg: '#EFF6FF', border: '#BFDBFE', icon: '✓', label: 'Ready',      message: 'Great news! Your order is ready for pickup or out for delivery.' },
    completed: { color: '#166534', bg: '#F0FDF4', border: '#BBF7D0', icon: '✓', label: 'Completed',  message: 'Your order has been completed. Thank you for using RapidSave.' },
    cancelled: { color: '#9F1239', bg: '#FFF1F2', border: '#FECDD3', icon: '✕', label: 'Cancelled',  message: 'Your order has been cancelled. Please contact the pharmacy for more information.' },
  };

  const s = statusConfig[status];

  await sendEmail({
    to:      user.email,
    subject: `RapidSave — Order ${s.label}`,
    html: baseTemplate(`
      <h2 style="margin:0 0 8px;color:#1B3A6B;font-size:22px;font-weight:700;">Order ${s.label}</h2>
      <p style="margin:0 0 24px;color:#64748B;font-size:15px;">Hello <strong style="color:#1E293B;">${user.name}</strong>, ${s.message}</p>

      <div style="background:${s.bg};border:1px solid ${s.border};border-radius:12px;padding:24px;margin:0 0 24px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding:8px 0;border-bottom:1px solid ${s.border};">
              <span style="color:#64748B;font-size:13px;">Order ID</span>
              <span style="float:right;color:#1E293B;font-size:13px;font-weight:600;">${order._id}</span>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 0;border-bottom:1px solid ${s.border};">
              <span style="color:#64748B;font-size:13px;">Total Amount</span>
              <span style="float:right;color:#1E293B;font-size:13px;font-weight:600;">${order.total_amount} RWF</span>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 0;">
              <span style="color:#64748B;font-size:13px;">Status</span>
              <span style="float:right;">
                <span style="background:${s.bg};color:${s.color};border:1px solid ${s.border};padding:2px 10px;border-radius:20px;font-size:12px;font-weight:600;">${s.label}</span>
              </span>
            </td>
          </tr>
        </table>
      </div>

      <p style="margin:0;color:#94A3B8;font-size:13px;">— The RapidSave Team</p>
    `),
  });
};

const sendPaymentVerificationEmail = async (user, order, action, reason = null) => {
  const isVerified = action === 'verify';

  await sendEmail({
    to:      user.email,
    subject: `RapidSave — Payment ${isVerified ? 'Verified' : 'Rejected'}`,
    html: baseTemplate(`
      <h2 style="margin:0 0 8px;color:#1B3A6B;font-size:22px;font-weight:700;">Payment ${isVerified ? 'Verified' : 'Rejected'}</h2>
      <p style="margin:0 0 24px;color:#64748B;font-size:15px;">Hello <strong style="color:#1E293B;">${user.name}</strong>,
        ${isVerified
          ? 'your payment has been verified. Your order will now be processed.'
          : 'your payment proof was rejected. Please upload a valid proof to continue.'
        }
      </p>

      <div style="background:${isVerified ? '#F0FDF4' : '#FFF1F2'};border:1px solid ${isVerified ? '#BBF7D0' : '#FECDD3'};border-radius:12px;padding:24px;margin:0 0 24px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding:8px 0;border-bottom:1px solid ${isVerified ? '#BBF7D0' : '#FECDD3'};">
              <span style="color:#64748B;font-size:13px;">Order ID</span>
              <span style="float:right;color:#1E293B;font-size:13px;font-weight:600;">${order._id}</span>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 0;border-bottom:1px solid ${isVerified ? '#BBF7D0' : '#FECDD3'};">
              <span style="color:#64748B;font-size:13px;">Amount</span>
              <span style="float:right;color:#1E293B;font-size:13px;font-weight:600;">${order.total_amount} RWF</span>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 0;">
              <span style="color:#64748B;font-size:13px;">Payment Status</span>
              <span style="float:right;">
                <span style="background:${isVerified ? '#F0FDF4' : '#FFF1F2'};color:${isVerified ? '#166534' : '#9F1239'};border:1px solid ${isVerified ? '#BBF7D0' : '#FECDD3'};padding:2px 10px;border-radius:20px;font-size:12px;font-weight:600;">${isVerified ? 'Verified' : 'Rejected'}</span>
              </span>
            </td>
          </tr>
          ${!isVerified && reason ? `
          <tr>
            <td style="padding:12px 0 0;">
              <div style="background:#FEF3C7;border-left:4px solid #F59E0B;border-radius:0 8px 8px 0;padding:12px 14px;">
                <p style="margin:0;color:#92400E;font-size:13px;"><strong>Reason:</strong> ${reason}</p>
              </div>
            </td>
          </tr>` : ''}
        </table>
      </div>

      <p style="margin:0;color:#94A3B8;font-size:13px;">— The RapidSave Team</p>
    `),
  });
};

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendWelcomeEmail,
  sendPasswordResetEmail,
  sendOrderStatusEmail,
  sendPaymentVerificationEmail,
};