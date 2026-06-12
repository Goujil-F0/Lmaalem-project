// controllers/messageController.js
const MessageModel = require('../models/messageModel');

const getChatHistory = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const messages = await MessageModel.getMessagesByBooking(bookingId);
        
        res.status(200).json({ success: true, data: messages });
    } catch (error) {
        console.error("Erreur récupération des messages:", error);
        res.status(500).json({ success: false, message: "Erreur serveur" });
    }
};

const markMessagesRead = async (req, res) => {
    try {
        await MessageModel.markAsRead(req.params.bookingId, req.params.userId);
        res.status(200).json({ success: true });
    } catch (error) {
        res.status(500).json({ success: false });
    }
};
module.exports = { getChatHistory, markMessagesRead }; // Export mis à jour