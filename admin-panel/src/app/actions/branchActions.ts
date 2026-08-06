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
    // Generate a unique branchId to prevent branches in the same city from overwriting each other
    let branchId = adminDb.collection('branches').doc().id;
    let uid = branchId;
    
    // 1. Create User in Firebase Auth for Mobile POS Login
    if (data.email && data.password) {
      const userRecord = await adminAuth.createUser({
        email: data.email,
        password: data.password,
        displayName: data.name,
      });
      uid = userRecord.uid;
      branchId = uid; // Keep them 1:1

      // Create mapping in users collection so Mobile App knows its location
      await adminDb.collection('users').doc(uid).set({
        uid,
        email: data.email,
        name: data.name,
        role: 'branch_pos', // Role khusus mesin kasir (tidak bisa masuk web admin)
        store_id: branchId, // IMPORTANT: We give the mobile app the branchId so its data is isolated!
        store_name: data.name,
        provinceId: data.provinceId,
        cityId: data.cityId,
        subscription_status: 'trial',
        trial_expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
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
      isActive: true,
      subscription_status: 'trial',
      trial_expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date().toISOString(),
    });

    // 3. Initialize empty PINs for the new branch using branchId as the container
    const pinsRef = adminDb
      .collection('stores')
      .doc(branchId) // Isolated by branchId
      .collection('settings')
      .doc('store_pins');

    await pinsRef.set({
      pin_kasir: '',
      pin_manager: '',
      pin_owner: ''
    });

    return { success: true, id: branchId };
  } catch (error: any) {
    console.error('Error creating branch:', error);
    return { success: false, error: error.message };
  }
}

export async function toggleBranchStatus(uid: string, branchId: string, currentStatus: boolean) {
  try {
    const newStatus = !currentStatus;
    
    // 1. Update Firebase Auth user (disable/enable)
    // Only attempt if it's a real Auth uid (not equal to branchId which we used as fallback)
    if (uid && uid !== branchId) {
      await adminAuth.updateUser(uid, { disabled: !newStatus });
    }

    // 2. Update branches collection
    await adminDb.collection('branches').doc(branchId).update({
      isActive: newStatus
    });

    return { success: true, isActive: newStatus };
  } catch (error: any) {
    console.error('Error toggling branch status:', error);
    return { success: false, error: error.message };
  }
}

export async function deleteBranch(branchId: string, uid: string) {
  try {
    // 1. Delete from Firebase Auth if it exists
    if (uid && uid !== branchId) {
      try {
        await adminAuth.deleteUser(uid);
      } catch (authErr) {
        console.warn('Auth user already deleted or not found:', authErr);
      }
      
      // 2. Delete from users collection mapping
      await adminDb.collection('users').doc(uid).delete();
    }

    // 3. Delete from branches collection
    await adminDb.collection('branches').doc(branchId).delete();

    // 4. Delete the store_pins document to clean up (optional but good for cleanup)
    await adminDb
      .collection('stores')
      .doc(branchId)
      .collection('settings')
      .doc('store_pins')
      .delete();

    // Note: Deleting a document does not delete its subcollections in Firestore, 
    // but the 'store_pins' is the only subcollection we created here. 
    // Actual transactions won't be deleted, preserving historical data!

    return { success: true };
  } catch (error: any) {
    console.error('Error deleting branch:', error);
    return { success: false, error: error.message };
  }
}

export async function updateBranch(branchId: string, newName: string, uid?: string, newPassword?: string, newEmail?: string) {
  try {
    const branchUpdates: any = { name: newName };
    if (newEmail) branchUpdates.email = newEmail;

    // Update data in branches collection
    await adminDb.collection('branches').doc(branchId).update(branchUpdates);

    // Update data in users collection if mapping exists
    if (uid && uid !== branchId) {
      await adminDb.collection('users').doc(uid).update(branchUpdates)
        .catch(err => console.warn('User mapping update warning:', err));
      
      const authUpdates: any = { displayName: newName };
      if (newPassword && newPassword.trim().length >= 6) {
        authUpdates.password = newPassword;
      }
      if (newEmail) {
        authUpdates.email = newEmail;
      }
      
      await adminAuth.updateUser(uid, authUpdates);
    }

    return { success: true };
  } catch (error: any) {
    console.error('Error updating branch:', error);
    return { success: false, error: error.message };
  }
}

export async function updateSubscriptionStatus(
  branchId: string,
  uid: string,
  status: 'trial' | 'active',
  expiresAt?: string
) {
  try {
    const updates: any = {
      subscription_status: status,
    };
    
    if (status === 'trial' && expiresAt) {
      updates.trial_expires_at = expiresAt;
    } else if (status === 'active') {
      updates.trial_expires_at = null;
    }

    await adminDb.collection('branches').doc(branchId).update(updates);
    
    if (uid) {
      await adminDb.collection('users').doc(uid).update(updates);
    }

    return { success: true };
  } catch (error: any) {
    console.error('Error updating subscription:', error);
    return { success: false, error: error.message };
  }
}
