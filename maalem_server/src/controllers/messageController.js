const MessageModel = require('../models/messageModel');

const normalizeMessagePayload = (payload) => {
    const bookingId = payload.booking_id ?? payload.bookingId;
    const senderId = payload.sender_id ?? payload.senderId;
    const content = typeof payload.content === 'string' ? payload.content.trim() : '';

    return {
        bookingId: Number(bookingId),
        senderId: Number(senderId),
        content
    };
};

const createMessage = async (payload) => {
    const { bookingId, senderId, content } = normalizeMessagePayload(payload);

    if (!Number.isInteger(bookingId) || !Number.isInteger(senderId) || !content) {
        const error = new Error('Message invalide.');
        error.statusCode = 400;
        throw error;
    }

    const booking = await MessageModel.getBookingById(bookingId);
    if (!booking) {
        const error = new Error('Reservation introuvable.');
        error.statusCode = 404;
        throw error;
    }

    const isParticipant =
        Number(booking.client_id) === senderId || Number(booking.artisan_id) === senderId;

    if (!isParticipant) {
        const error = new Error('Vous ne pouvez pas envoyer un message sur cette reservation.');
        error.statusCode = 403;
        throw error;
    }

    return MessageModel.saveMessage(bookingId, senderId, content);
};

const getChatHistory = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const messages = await MessageModel.getMessagesByBooking(bookingId);

        res.status(200).json({ success: true, data: messages });
    } catch (error) {
        console.error('Erreur recuperation des messages:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur' });
    }
};

const sendMessage = async (req, res) => {
    try {
        const savedMessage = await createMessage(req.body);

        const io = req.app.get('socketio');
        if (io) {
            io.to(savedMessage.booking_id.toString()).emit('receive_message', savedMessage);
        }

        res.status(201).json({ success: true, data: savedMessage });
    } catch (error) {
        console.error('Erreur envoi message:', error);
        res.status(error.statusCode || 500).json({
            success: false,
            message: error.statusCode ? error.message : 'Erreur serveur'
        });
    }
};

module.exports = { getChatHistory, sendMessage, createMessage };
