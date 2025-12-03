const { Queue, Worker } = require('bullmq');
const redisClient = require('../config/redis');
const mailService = require('./mailService');
const Notificacion = require('../models/NotificacionModel');
const logger = require('../config/logger');

// Define a connection for the queue and worker
const connection = {
  client: redisClient,
};

// Create a new Queue
const notificationQueue = new Queue('notificationQueue', { connection });

// Define the Worker
const notificationWorker = new Worker('notificationQueue', async (job) => {
  const { type, data } = job;

  try {
    switch (type) {
      case 'sendEmail':
        logger.info(`Processing sendEmail job for user ${data.userId} to ${data.to} with template ${data.templateName}`, { requestId: job.data.requestId });
        await mailService.sendEmail(data.to, data.subject, data.templateName, data.context);
        // Update notification status in DB
        if (data.notificationId) {
          await Notificacion.update({ estado: 'enviado', enviado_at: new Date(), retry_count: job.attemptsMade }, { where: { id: data.notificationId } });
        }
        logger.info(`Email sent successfully for job ${job.id}`, { requestId: job.data.requestId });
        break;
      case 'activityReminder':
        logger.info(`Processing activityReminder job for activity ${data.activityId}`, { requestId: job.data.requestId });
        // Logic to fetch activity details and send reminder email
        // This will involve fetching activity, user details, and composing email
        // For now, just log
        logger.info(`Reminder processed for activity ${data.activityId}`, { requestId: job.data.requestId });
        break;
      // Add other job types as needed
      default:
        logger.warn(`Unknown job type: ${type}`, { requestId: job.data.requestId });
    }
  } catch (error) {
    logger.error(`Job ${job.id} failed: ${error.message}`, { jobType: type, jobId: job.id, data: job.data, error: error.message, requestId: job.data.requestId });
    // Update notification status to failed in DB
    if (data.notificationId) {
      await Notificacion.update({ estado: 'fallido', error_msg: error.message, retry_count: job.attemptsMade }, { where: { id: data.notificationId } });
    }
    throw error; // Re-throw to allow BullMQ to handle retries
  }
}, { connection, concurrency: 5 }); // Process 5 jobs at a time

notificationWorker.on('completed', (job) => {
  logger.info(`Job ${job.id} of type ${job.name} completed successfully`, { requestId: job.data.requestId });
});

notificationWorker.on('failed', (job, err) => {
  logger.error(`Job ${job.id} of type ${job.name} failed with error: ${err.message}`, { requestId: job.data.requestId });
});

notificationWorker.on('error', (err) => {
  logger.error(`Worker experienced an error: ${err.message}`);
});

// Function to add a job to the queue
const addNotificationJob = async (type, data, options = {}) => {
  return notificationQueue.add(type, data, {
    attempts: 3, // Retry 3 times
    backoff: {
      type: 'exponential',
      delay: 1000, // 1s, 2s, 4s
    },
    removeOnComplete: true, // Remove job from queue when completed
    removeOnFail: false, // Keep failed jobs in queue for inspection (will go to DLQ after all retries)
    ...options,
  });
};

// Function to start the worker
const startWorker = () => {
  if (!notificationWorker.isRunning()) {
    notificationWorker.run();
    logger.info('Notification worker started.');
  }
};

module.exports = {
  notificationQueue,
  addNotificationJob,
  startWorker,
};
