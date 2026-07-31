'use server';

import * as admin from 'firebase-admin';

// Initialize Firebase Admin (Only once)
if (!admin.apps.length) {
  try {
    admin.initializeApp();
  } catch (error) {
    console.error('Firebase admin initialization error', error);
  }
}

export async function createEmployeeAccount(formData: FormData) {
  try {
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;
    const name = formData.get('name') as string;
    const role = formData.get('role') as string;
    const provinceId = 'jatim'; // Hardcoded for this demo, normally taken from Superadmin session
    const cityId = 'malang';

    // 1. Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // 2. Save role to Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      name,
      email,
      role,
      province_id: provinceId,
      city_id: cityId,
    });

    return { success: true, message: 'Karyawan berhasil ditambahkan!' };
  } catch (error: any) {
    return { success: false, message: error.message };
  }
}
