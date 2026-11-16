const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');
const taskRoutes = require('./routes/taskRoutes');
const userRoutes = require('./routes/userRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const taskShareRoutes = require('./routes/taskShareRoutes');
const notificationRoutes = require('./routes/notificationRoutes');


const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks/:id/assignees', assignmentRoutes);
app.use('/api/tasks/:id/shares', taskShareRoutes);
app.use('/api/notifications', notificationRoutes);


app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use(notFound);
app.use(errorHandler);
module.exports = app;