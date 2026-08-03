'use server';

import { adminAuth, adminDb } from '@/lib/firebaseAdmin';

export async function createBranchAccount(data: {
  email: string;
  password?: string;
  name: string;
  provinceId: string;
  cityId: string;
}) {
  try {
    const branchId = `${data.provinceId}_${data.cityId}`;
    
    let uid = branchId;
    
    // 1. Create User in Firebase Auth for Mobile POS Login
    if (data.email && data.password) {
      const userRecord = await adminAuth.createUser({
        email: data.email,
        password: data.password,
        displayName: data.name,
      });
      uid = userRecord.uid;

      // Create mapping in users collection so Mobile App knows its location
      await adminDb.collection('users').doc(uid).set({
        uid,
        email: data.email,
        name: data.name,
        role: 'branch_pos', // Role khusus mesin kasir (tidak bisa masuk web admin)
        provinceId: data.provinceId,
        cityId: data.cityId,
        createdAt: new Date().toISOString(),
      });
    }

    // 2. Create Branch Info in Firestore (for Web Admin viewing)
    await adminDb.collection('branches').doc(branchId).set({
      name: data.name,
      email: data.email || '',
      provinceId: data.provinceId,
      cityId: data.cityId,
      uid: uid,
      createdAt: new Date().toISOString(),
    });

    // 3. Initialize empty PINs for the new branch
    const pinsRef = adminDb
      .collection('provinces')
      .doc(data.provinceId)
      .collection('cities')
      .doc(data.cityId)
      .collection('settings')
      .doc('store_pins');

    await pinsRef.set({
      pin_kasir: '',
      pin_manager: '',
      pin_owner: '',
    });

    return { success: true, id: branchId };
  } catch (error: any) {
    console.error('Error creating branch:', error);
    return { success: false, error: error.message };
  }
}
