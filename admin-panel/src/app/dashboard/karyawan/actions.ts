'use server';

import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';

// Initialize Firebase Admin (Only once)
if (!getApps().length) {
  try {
    const serviceAccountPath = path.join(process.cwd(), 'service-account.json');
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    
    initializeApp({
      credential: cert(serviceAccount)
    });
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
    const callerRole = formData.get('callerRole') as string;
    const callerCityId = formData.get('callerCityId') as string;
    
    // Security logic
    if (callerRole !== 'admin' && callerRole !== 'superadmin') {
      throw new Error('Unauthorized');
    }
    
    let provinceId = callerRole === 'superadmin' ? ((formData.get('provinceId') as string) || 'jatim') : 'jatim';
    let cityId = callerCityId;

    if (callerRole === 'superadmin') {
      cityId = (formData.get('cityId') as string) || '';
    } else {
      if (role === 'admin') {
        throw new Error('Admin cabang tidak dapat membuat akun Admin lain.');
      }
    }

    // Validasi 1 Cabang = 1 Role (Kecuali Superadmin/Admin Cabang)
    if (['owner', 'manager', 'kasir'].includes(role)) {
      const existingUserQuery = await getFirestore().collection('users')
        .where('city_id', '==', cityId)
        .where('role', '==', role)
        .get();
        
      if (!existingUserQuery.empty) {
        throw new Error(`Slot untuk peran ${role} di cabang ini sudah terisi!`);
      }
    }

    // 1. Create user in Firebase Auth
    const userRecord = await getAuth().createUser({
      email,
      password,
      displayName: name,
    });

    // 2. Save role to Firestore
    await getFirestore().collection('users').doc(userRecord.uid).set({
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

export async function updateUserCredentials(formData: FormData) {
  try {
    const targetUid = formData.get('targetUid') as string;
    const newEmail = formData.get('newEmail') as string;
    const newPassword = formData.get('newPassword') as string;
    const newName = formData.get('newName') as string;
    const callerRole = formData.get('callerRole') as string;
    const callerCityId = formData.get('callerCityId') as string;

    if (!targetUid) throw new Error('Target UID tidak valid.');

    // 1. Dapatkan data target dari Firestore
    const targetDoc = await getFirestore().collection('users').doc(targetUid).get();
    if (!targetDoc.exists) {
      throw new Error('User tidak ditemukan di database.');
    }
    const targetData = targetDoc.data();

    // 2. Proteksi Keamanan
    if (callerRole !== 'superadmin') {
      if (callerRole !== 'admin') {
        throw new Error('Hanya Admin / Superadmin yang bisa mereset.');
      }
      if (targetData?.city_id !== callerCityId) {
        throw new Error('Anda tidak memiliki wewenang mengubah data di cabang lain!');
      }
      if (targetData?.role === 'superadmin' || targetData?.role === 'admin') {
        throw new Error('Admin cabang tidak boleh mengubah data Superadmin / Admin.');
      }
    }

    // 3. Update Auth
    const updateData: any = {};
    if (newEmail) updateData.email = newEmail;
    if (newPassword) updateData.password = newPassword;
    if (newName) updateData.displayName = newName;
    
    if (Object.keys(updateData).length > 0) {
      await getAuth().updateUser(targetUid, updateData);
    }

    // 4. Update Firestore jika email atau nama berubah
    const firestoreUpdate: any = {};
    if (newEmail) firestoreUpdate.email = newEmail;
    if (newName) firestoreUpdate.name = newName;

    if (Object.keys(firestoreUpdate).length > 0) {
      await getFirestore().collection('users').doc(targetUid).update(firestoreUpdate);
    }

    return { success: true, message: `Data akun berhasil diperbarui!` };
  } catch (error: any) {
    return { success: false, message: error.message };
  }
}
