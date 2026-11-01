const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');
const taskRoutes = require('./routes/taskRoutes');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);


app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use(notFound);
app.use(errorHandler);
module.exports = app;