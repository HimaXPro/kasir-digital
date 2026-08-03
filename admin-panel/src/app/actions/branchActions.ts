'use server';

import { adminAuth, adminDb } from '@/lib/firebaseAdmin';

export async function createBranchAccount(data: {
  email: string;
  password: string;
  name: string;
  provinceId: string;
  cityId: string;
}) {
  try {
    // 1. Create User in Firebase Auth
    const userRecord = await adminAuth.createUser({
      email: data.email,
      password: data.password,
      displayName: data.name,
    });

    const uid = userRecord.uid;

    // 2. Create User Profile in Firestore with role 'admin'
    await adminDb.collection('users').doc(uid).set({
      uid,
      email: data.email,
      name: data.name,
      role: 'admin',
      provinceId: data.provinceId,
      cityId: data.cityId,
      createdAt: new Date().toISOString(),
    });

    // 3. Initialize default PINs for the new branch
    const pinsRef = adminDb
      .collection('provinces')
      .doc(data.provinceId)
      .collection('cities')
      .doc(data.cityId)
      .collection('settings')
      .doc('store_pins');

    await pinsRef.set({
      pin_kasir: '111111',
      pin_manager: '222222',
      pin_owner: '333333',
    });

    return { success: true, uid };
  } catch (error: any) {
    console.error('Error creating branch account:', error);
    return { success: false, error: error.message };
  }
}
