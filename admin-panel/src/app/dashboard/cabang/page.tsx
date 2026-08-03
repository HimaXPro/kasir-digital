'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { createBranchAccount } from '@/app/actions/branchActions';

interface BranchUser {
  id: string;
  name: string;
  email: string;
  provinceId: string;
  cityId: string;
  role: string;
}

export default function CabangPage() {
  const [branches, setBranches] = useState<BranchUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    provinceId: '',
    cityId: '',
  });

  useEffect(() => {
    // Only fetch users with role 'admin'
    const q = query(collection(db, 'users'), where('role', '==', 'admin'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const branchesData: BranchUser[] = [];
      snapshot.forEach((doc) => {
        branchesData.push({ id: doc.id, ...doc.data() } as BranchUser);
      });
      setBranches(branchesData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    const res = await createBranchAccount({
      ...formData,
      provinceId: formData.provinceId.toLowerCase().trim(),
      cityId: formData.cityId.toLowerCase().trim(),
    });

    setIsSubmitting(false);

    if (res.success) {
      alert('Cabang berhasil didaftarkan!');
      setIsModalOpen(false);
      setFormData({ name: '', email: '', password: '', provinceId: '', cityId: '' });
    } else {
      alert('Gagal mendaftar: ' + res.error);
    }
  };

  if (loading) return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat data cabang...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '8px'}}>Manajemen Cabang</h1>
          <p style={{color: 'var(--text-muted)'}}>
            Daftar Admin Cabang yang terdaftar di sistem.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setIsModalOpen(true)}>
          + Tambah Cabang
        </button>
      </div>

      <div className="card">
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #eaeaea', textAlign: 'left' }}>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>Nama Cabang</th>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>Email</th>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>Provinsi</th>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>Kota</th>
            </tr>
          </thead>
          <tbody>
            {branches.map((b) => (
              <tr key={b.id} style={{ borderBottom: '1px solid #eaeaea' }}>
                <td style={{ padding: '12px 8px', fontWeight: 600 }}>{b.name}</td>
                <td style={{ padding: '12px 8px', color: 'var(--text-muted)' }}>{b.email}</td>
                <td style={{ padding: '12px 8px' }}>{b.provinceId}</td>
                <td style={{ padding: '12px 8px' }}>{b.cityId}</td>
              </tr>
            ))}
            {branches.length === 0 && (
              <tr>
                <td colSpan={4} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  Belum ada cabang terdaftar.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Modal Tambah Cabang */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 100,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div className="card" style={{ width: '100%', maxWidth: '500px', maxHeight: '90vh', overflowY: 'auto' }}>
            <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '8px'}}>Tambah Cabang Baru</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: '24px', fontSize: '13px' }}>
              Akun yang didaftarkan akan mendapat peran Admin Cabang.
            </p>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Cabang (misal: Toko Jakarta)</label>
                <input 
                  type="text" 
                  className="input-field"
                  required 
                  value={formData.name} 
                  onChange={(e) => setFormData({...formData, name: e.target.value})} 
                />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login</label>
                <input 
                  type="email" 
                  className="input-field"
                  required 
                  value={formData.email} 
                  onChange={(e) => setFormData({...formData, email: e.target.value})} 
                />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password</label>
                <input 
                  type="password" 
                  className="input-field"
                  required 
                  minLength={6}
                  value={formData.password} 
                  onChange={(e) => setFormData({...formData, password: e.target.value})} 
                />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>ID Provinsi (tanpa spasi, misal: jakarta)</label>
                <input 
                  type="text" 
                  className="input-field"
                  required 
                  value={formData.provinceId} 
                  onChange={(e) => setFormData({...formData, provinceId: e.target.value})} 
                />
              </div>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>ID Kota (tanpa spasi, misal: jaksel)</label>
                <input 
                  type="text" 
                  className="input-field"
                  required 
                  value={formData.cityId} 
                  onChange={(e) => setFormData({...formData, cityId: e.target.value})} 
                />
              </div>
              
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} style={{ background: 'transparent', border: '1px solid #ddd', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer', fontWeight: 500 }}>
                  Batal
                </button>
                <button type="submit" className="btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Mendaftarkan...' : 'Simpan & Daftarkan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
