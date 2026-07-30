// aw
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();

// IMPORTANT: Replace with actual Server Key
const SERVER_KEY = "SB-Mid-server-xxxxxxxxxxxxxxxxxxxxxxxx";

const coreApi = new midtransClient.CoreApi({
  isProduction: false,
  serverKey: SERVER_KEY,
  clientKey: "SB-Mid-client-xxxxxxxxxxxxxxxxxxxxxxxx"
});

// Endpoint to generate QRIS
exports.generateQris = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { transactionId, amount, items, customerName, email } = req.body;

      if (!transactionId || !amount) {
        return res.status(400).send('Missing transactionId or amount');
      }

      let parameter = {
        payment_type: "qris",
        transaction_details: {
          order_id: transactionId,
          gross_amount: amount
        },
        customer_details: {
          first_name: customerName || "Kasir",
          email: email || "kasir@bhayangkari.com"
        }
      };

      if (items && Array.isArray(items)) {
        parameter.item_details = items.map(item => ({
          id: item.product_id || 'ITEM-1',
          price: item.price,
          quantity: item.quantity,
          name: (item.product_name || 'Item').substring(0, 50)
        }));
      }

      const chargeResponse = await coreApi.charge(parameter);
      
      // The QR code string is typically returned in actions array
      let qrString = "";
      let qrUrl = "";
      
      if (chargeResponse.actions) {
        const generateAction = chargeResponse.actions.find(a => a.name === 'generate-qr-code');
        if (generateAction) qrUrl = generateAction.url;
      }
      
      if (chargeResponse.qr_string) {
        qrString = chargeResponse.qr_string;
      }

      return res.status(200).json({
        success: true,
        transactionId: transactionId,
        midtransId: chargeResponse.transaction_id,
        status: chargeResponse.transaction_status,
        qrString: qrString,
        qrUrl: qrUrl
      });
    } catch (error) {
      console.error("Midtrans Error:", error);
      return res.status(500).json({ success: false, error: error.message });
    }
  });
});

// Midtrans Webhook (Notification URL)
exports.midtransWebhook = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const notificationJson = req.body;
      const statusResponse = await coreApi.transaction.notification(notificationJson);
      
      const orderId = statusResponse.order_id;
      const transactionStatus = statusResponse.transaction_status;
      const fraudStatus = statusResponse.fraud_status;

      console.log(`Notification received for order: ${orderId}. Status: ${transactionStatus}`);

      // We need to find which city/tenant this order belongs to
      // Since orderId is just the doc ID, we can do a collectionGroup query in Firestore
      const transactionsRef = db.collectionGroup('transactions').where('id', '==', orderId);
      const snapshot = await transactionsRef.get();

      if (snapshot.empty) {
        console.warn(`Order ${orderId} not found in Firestore`);
        return res.status(404).send('Order not found');
      }

      const docRef = snapshot.docs[0].ref;

      let paymentStatus = 'PENDING';
      
      if (transactionStatus === 'capture') {
        if (fraudStatus === 'challenge') {
          paymentStatus = 'CHALLENGE';
        } else if (fraudStatus === 'accept') {
          paymentStatus = 'PAID';
        }
      } else if (transactionStatus === 'settlement') {
        paymentStatus = 'PAID';
      } else if (transactionStatus === 'cancel' || transactionStatus === 'deny' || transactionStatus === 'expire') {
        paymentStatus = 'FAILED';
      } else if (transactionStatus === 'pending') {
        paymentStatus = 'PENDING';
      }

      // Update the transaction in Firestore
      await docRef.update({
        qris_status: paymentStatus,
        updated_at: new Date().toISOString()
      });

      return res.status(200).send('OK');
    } catch (error) {
      console.error("Webhook Error:", error);
      return res.status(500).json({ success: false, error: error.message });
    }
  });
});
