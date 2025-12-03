const nodemailer = require('nodemailer');
const handlebars = require('handlebars');
const fs = require('fs').promises;
const path = require('path');
const { EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASSWORD, EMAIL_FROM, APP_NAME, BASE_URL_API } = require('../config/env');
const logger = require('../config/logger');

const transporter = nodemailer.createTransport({
  host: EMAIL_HOST,
  port: EMAIL_PORT,
  secure: EMAIL_PORT == 465, // true for 465, false for other ports
  auth: {
    user: EMAIL_USER,
    pass: EMAIL_PASSWORD,
  },
});

const templateCache = {};

const loadTemplate = async (templateName) => {
  if (templateCache[templateName]) {
    return templateCache[templateName];
  }

  const templatePath = path.join(__dirname, 'emailTemplates', `${templateName}.html`);
  try {
    const source = await fs.readFile(templatePath, 'utf-8');
    const template = handlebars.compile(source);
    templateCache[templateName] = template;
    return template;
  } catch (error) {
    logger.error(`Error loading email template ${templateName}: ${error.message}`);
    throw new Error(`Could not load email template: ${templateName}`);
  }
};

const sendEmail = async (to, subject, templateName, context = {}) => {
  try {
    const baseTemplate = await loadTemplate('base');
    const contentTemplate = await loadTemplate(templateName);

    // Default context values
    const fullContext = {
      appName: APP_NAME || 'Administrativo TIGO',
      year: new Date().getFullYear(),
      subject: subject,
      baseUrl: BASE_URL_API || 'http://localhost:3000',
      ...context,
    };

    const contentHtml = contentTemplate(fullContext);
    const finalHtml = baseTemplate({ ...fullContext, body: contentHtml });

    const mailOptions = {
      from: EMAIL_FROM,
      to,
      subject,
      html: finalHtml,
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info(`Email sent: ${info.messageId} to ${to} for template ${templateName}`);
    return info;
  } catch (error) {
    logger.error(`Error sending email to ${to} for template ${templateName}: ${error.message}`);
    throw new Error('Could not send email');
  }
};

module.exports = {
  sendEmail,
};
