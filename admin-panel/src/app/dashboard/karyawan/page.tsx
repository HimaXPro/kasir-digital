'use client';

import { useState, useEffect } from 'react';
import { createEmployeeAccount, updateUserCredentials } from './actions';
import { auth, db } from '@/lib/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

interface UserData {
  id: string;
  name: string;
  email: string;
  role: string;
  city_id: string;
}

export default function KelolaKaryawanPage() {
  const [loading, setLoading] = useState(true);
  const [callerRole, setCallerRole] = useState('');
  const [callerCityId, setCallerCityId] = useState('');
  
  // Data slot
  const [users, setUsers] = useState<UserData[]>([]);

  // Modal State
  const [activeModal, setActiveModal] = useState<'create' | 'edit' | null>(null);
  const [selectedRole, setSelectedRole] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserData | null>(null);
  
  // Form State
  const [formLoading, setFormLoading] = useState(false);
  const [formMessage, setFormMessage] = useState('');
  const [isError, setIsError] = useState(false);

  // Location mapping for Superadmin
  const [locations, setLocations] = useState<Record<string, string[]>>({});
  const [selectedProv, setSelectedProv] = useState('');

  // Load Data
  const loadData = async (cityId: string, role: string) => {
    setLoading(true);
    try {
      if (role === 'superadmin') {
        // Fetch all users to map provinces and cities
        const snap = await getDocs(collection(db, 'users'));
        const locMap: Record<string, Set<string>> = {};
        snap.docs.forEach(doc => {
          const d = doc.data();
          const p = d.province_id;
          const c = d.city_id;
          if (p && c) {
            if (!locMap[p]) locMap[p] = new Set();
            locMap[p].add(c);
          }
        });
        const finalMap: Record<string, string[]> = {};
        Object.keys(locMap).forEach(k => {
          finalMap[k] = Array.from(locMap[k]);
        });
        setLocations(finalMap);
      } else {
        const q = query(collection(db, 'users'), where('city_id', '==', cityId));
        const snap = await getDocs(q);
        const fetchedUsers = snap.docs.map(doc => ({ id: doc.id, ...doc.data() } as UserData));
        setUsers(fetchedUsers);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (user) => {
      if (user) {
        const userDocRef = await getDocs(query(collection(db, 'users'), where('email', '==', user.email)));
        if (!userDocRef.empty) {
          const uData = userDocRef.docs[0].data();
          const role = uData.role || 'admin';
          setCallerRole(role);
          const cId = uData.city_id || '';
          setCallerCityId(cId);
          if (role === 'superadmin') {
            loadData('', role);
          } else if (cId) {
            loadData(cId, role);
          } else {
            setLoading(false);
          }
        } else {
          setLoading(false);
        }
      } else {
        setLoading(false);
      }
    });
    return () => unsubscribe();
  }, []);

  const handleCreate = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormLoading(true);
    setFormMessage('');

    const formData = new FormData(e.currentTarget);
    formData.append('callerRole', callerRole);
    formData.append('callerCityId', callerCityId);
    formData.append('role', selectedRole);

    const result = await createEmployeeAccount(formData);

    setIsError(!result.success);
    setFormMessage(result.message);
    setFormLoading(false);

    if (result.success) {
      (e.target as HTMLFormElement).reset();
      loadData(callerCityId);
      setTimeout(() => setActiveModal(null), 1500);
    }
  };

  const handleUpdate = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormLoading(true);
    setFormMessage('');

    const formData = new FormData(e.currentTarget);
    formData.append('callerRole', callerRole);
    formData.append('callerCityId', callerCityId);
    if (selectedUser) formData.append('targetUid', selectedUser.id);

    const result = await updateUserCredentials(formData);

    setIsError(!result.success);
    setFormMessage(result.message);
    setFormLoading(false);
    if (result.success) {
      (e.target as HTMLFormElement).reset();
      loadData(callerCityId);
      setTimeout(() => setActiveModal(null), 1500);
    }
  };

  const openCreateModal = (role: string) => {
    setSelectedRole(role);
    setFormMessage('');
    setActiveModal('create');
  };

  const openEditModal = (user: UserData) => {
    setSelectedUser(user);
    setFormMessage('');
    setActiveModal('edit');
  };

  const renderSlot = (roleId: string, roleName: string) => {
    const user = users.find(u => u.role === roleId);

    return (
      <div className="card" style={{ flex: '1', minWidth: '280px', display: 'flex', flexDirection: 'column' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: 'var(--text-muted)', marginBottom: '16px' }}>Slot: {roleName}</h3>
        
        {user ? (
          <div style={{ flex: 1 }}>
            <div style={{ marginBottom: '12px' }}>
              <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>Nama Karyawan</p>
              <p style={{ fontSize: '16px', fontWeight: '600' }}>{user.name}</p>
            </div>
            <div style={{ marginBottom: '24px' }}>
              <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>Email Akses</p>
              <p style={{ fontSize: '14px', color: 'var(--primary)' }}>{user.email}</p>
            </div>
            <button 
              onClick={() => openEditModal(user)}
              className="btn-primary" 
              style={{ width: '100%', background: 'transparent', color: 'var(--accent)', border: '1px solid var(--accent)' }}>
              Edit Akun
            </button>
          </div>
        ) : (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', padding: '24px 0' }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: 'rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px', color: 'var(--text-muted)' }}>
              +
            </div>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>Slot Kosong</p>
            <button 
              onClick={() => openCreateModal(roleId)}
              className="btn-primary" 
              style={{ width: '100%' }}>
              Buat Akun {roleName}
            </button>
          </div>
        )}
      </div>
    );
  };

  return (
    <div>
      <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '8px'}}>Kelola Karyawan</h1>
      <p style={{color: 'var(--text-muted)', marginBottom: '32px'}}>
        {callerRole === 'superadmin' 
          ? 'Manajemen Admin Cabang (Pusat Kendali)' 
          : `Manajemen slot karyawan untuk cabang ${callerCityId.toUpperCase() || '...'}. (Aturan: 1 Cabang = 1 Akun per Peran)`}
      </p>
      
      {loading ? (
        <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat data karyawan...</div>
      ) : callerRole === 'superadmin' ? (
        <div className="card" style={{ maxWidth: '600px' }}>
          <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '24px'}}>Buat Akun Admin Cabang Baru</h2>
          
          <form onSubmit={(e) => {
            e.preventDefault();
            const form = e.currentTarget as HTMLFormElement;
            const data = new FormData(form);
            data.append('callerRole', callerRole);
            data.append('callerCityId', callerCityId);
            data.append('role', 'admin');
            
            setFormLoading(true);
            setFormMessage('');
            
            createEmployeeAccount(data).then(result => {
              setIsError(!result.success);
              setFormMessage(result.message);
              setFormLoading(false);
              if (result.success) form.reset();
            }).catch(err => {
              setIsError(true);
              setFormMessage(err.message || 'Terjadi kesalahan jaringan.');
              setFormLoading(false);
            });
          }} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div>
              <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Admin</label>
              <input type="text" name="name" className="input-field" placeholder="Nama Admin" required />
            </div>
            <div>
              <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login</label>
              <input type="email" name="email" className="input-field" placeholder="admin@toko.com" required />
            </div>
            <div>
              <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password</label>
              <input type="password" name="password" className="input-field" placeholder="Minimal 6 karakter" required minLength={6} />
            </div>
            <div>
              <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Provinsi Cabang</label>
              <input 
                type="text" 
                name="provinceId" 
                list="prov-list"
                className="input-field" 
                placeholder="Pilih atau ketik provinsi (misal: jatim)" 
                required 
                onChange={(e) => setSelectedProv(e.target.value)}
              />
              <datalist id="prov-list">
                {Object.keys(locations).map(p => <option key={p} value={p} />)}
              </datalist>
            </div>
            
            <div>
              <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>ID Kota Cabang</label>
              <input 
                type="text" 
                name="cityId" 
                list="city-list"
                className="input-field" 
                placeholder="Pilih atau ketik kota (misal: malang)" 
                required 
              />
              <datalist id="city-list">
                {(locations[selectedProv] || []).map(c => <option key={c} value={c} />)}
              </datalist>
            </div>

            <button type="submit" className="btn-primary" disabled={formLoading} style={{marginTop: '12px'}}>
              {formLoading ? 'Memproses...' : 'Buat Akun Admin'}
            </button>
            {formMessage && (
              <div style={{ marginTop: '12px', padding: '12px', borderRadius: '8px', backgroundColor: isError ? 'rgba(255,0,0,0.1)' : 'rgba(0,255,0,0.1)', color: isError ? 'var(--danger)' : 'var(--accent)', border: `1px solid ${isError ? 'rgba(255,0,0,0.2)' : 'rgba(0,255,0,0.2)'}` }}>
                {formMessage}
              </div>
            )}
          </form>
        </div>
      ) : (
        <div style={{display: 'flex', gap: '24px', flexWrap: 'wrap'}}>
          {renderSlot('owner', 'Owner / Pemilik')}
          {renderSlot('manager', 'Manager')}
          {renderSlot('kasir', 'Kasir')}
        </div>
      )}

      {/* Modal Buat Akun (Khusus Admin Cabang) */}
      {activeModal === 'create' && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: '20px' }}>
          <div className="card" style={{ width: '100%', maxWidth: '400px', position: 'relative' }}>
            <button onClick={() => setActiveModal(null)} style={{ position: 'absolute', top: '16px', right: '16px', background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: '20px' }}>&times;</button>
            <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '24px'}}>Buat Akun {selectedRole.toUpperCase()}</h2>
            
            {formMessage && (
              <div style={{ padding: '12px', marginBottom: '20px', borderRadius: '8px', backgroundColor: isError ? 'rgba(255,0,0,0.1)' : 'rgba(0,255,0,0.1)', color: isError ? 'var(--danger)' : 'var(--accent)', border: `1px solid ${isError ? 'rgba(255,0,0,0.2)' : 'rgba(0,255,0,0.2)'}` }}>
                {formMessage}
              </div>
            )}

            <form onSubmit={handleCreate} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Karyawan</label>
                <input type="text" name="name" className="input-field" placeholder="Budi Santoso" required />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login</label>
                <input type="email" name="email" className="input-field" placeholder="email@toko.com" required />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password Awal</label>
                <input type="password" name="password" className="input-field" placeholder="Minimal 6 karakter" required minLength={6} />
              </div>
              
              {callerRole === 'superadmin' && (
                <div>
                  <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>ID Kota Cabang</label>
                  <input type="text" name="cityId" className="input-field" placeholder="Isi id kota (misal: malang)" required />
                </div>
              )}

              <button type="submit" className="btn-primary" disabled={formLoading} style={{marginTop: '12px'}}>
                {formLoading ? 'Memproses...' : 'Simpan Akun Baru'}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Modal Edit/Reset Akun */}
      {activeModal === 'edit' && selectedUser && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: '20px' }}>
          <div className="card" style={{ width: '100%', maxWidth: '400px', position: 'relative' }}>
            <button onClick={() => setActiveModal(null)} style={{ position: 'absolute', top: '16px', right: '16px', background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: '20px' }}>&times;</button>
            <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '8px', color: 'var(--accent)'}}>Verifikasi & Pemulihan</h2>
            <p style={{color: 'var(--text-muted)', fontSize: '13px', marginBottom: '24px'}}>Edit kredensial untuk <strong>{selectedUser.name}</strong> ({selectedUser.role}).</p>
            
            {formMessage && (
              <div style={{ padding: '12px', marginBottom: '20px', borderRadius: '8px', backgroundColor: isError ? 'rgba(255,0,0,0.1)' : 'rgba(0,255,0,0.1)', color: isError ? 'var(--danger)' : 'var(--accent)', border: `1px solid ${isError ? 'rgba(255,0,0,0.2)' : 'rgba(0,255,0,0.2)'}` }}>
                {formMessage}
              </div>
            )}

            <form onSubmit={handleUpdate} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Baru (Opsional)</label>
                <input type="text" name="newName" className="input-field" placeholder="Kosongkan jika tidak diubah" defaultValue={selectedUser.name} />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Baru (Opsional)</label>
                <input type="email" name="newEmail" className="input-field" placeholder="Kosongkan jika tidak diubah" defaultValue={selectedUser.email} />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password Baru (Opsional)</label>
                <input type="text" name="newPassword" className="input-field" placeholder="Ketik sandi baru" minLength={6} />
              </div>
              <button type="submit" className="btn-primary" disabled={formLoading} style={{marginTop: '12px'}}>
                {formLoading ? 'Memproses...' : 'Terapkan Perubahan'}
              </button>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
