'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { createBranchAccount, toggleBranchStatus, deleteBranch, updateBranch, updateSubscriptionStatus } from '@/app/actions/branchActions';

interface BranchInfo {
  id: string;
  name: string;
  email: string;
  uid: string;
  provinceId?: string; // Optional because we just added it back, older stores might not have it
  cityId?: string;     // Optional because older stores might not have it
  isActive?: boolean;
  subscription_status?: 'trial' | 'active';
  trial_expires_at?: string;
}

interface Region {
  id: string;
  name: string;
}

const formatId = (name: string) => {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
};

const Countdown = ({ expiresAt }: { expiresAt: string }) => {
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [isExpired, setIsExpired] = useState(false);

  useEffect(() => {
    const calc = () => {
      const diff = new Date(expiresAt).getTime() - Date.now();
      if (diff <= 0) {
        setTimeLeft('Expired');
        setIsExpired(true);
        return;
      }
      
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);
      
      if (hours > 24) {
        const days = Math.floor(hours / 24);
        setTimeLeft(`Sisa ${days} hari`);
      } else if (hours > 0) {
        setTimeLeft(`Sisa ${hours}j ${minutes}m`);
      } else {
        setTimeLeft(`Sisa ${minutes}m ${seconds}d`);
      }
    };
    
    calc();
    const interval = setInterval(calc, 1000);
    return () => clearInterval(interval);
  }, [expiresAt]);

  return (
    <div style={{ fontSize: '11px', color: isExpired ? 'var(--danger)' : 'var(--text-muted)', marginTop: '4px', textAlign: 'center', fontWeight: isExpired ? 'bold' : 'normal' }}>
      {timeLeft}
    </div>
  );
};

export default function CabangPage() {
  const [branches, setBranches] = useState<BranchInfo[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<BranchInfo | null>(null);

  const [isSubmitting, setIsSubmitting] = useState(false);

  // Filters
  const [filterName, setFilterName] = useState('');
  const [filterProvince, setFilterProvince] = useState('');
  const [filterCity, setFilterCity] = useState('');

  // Region Data
  const [provinces, setProvinces] = useState<Region[]>([]);
  const [cities, setCities] = useState<Region[]>([]);
  const [loadingProvinces, setLoadingProvinces] = useState(false);
  const [loadingCities, setLoadingCities] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    provinceId: '',
    provinceName: '',
    cityId: '',
    cityName: '',
  });

  const [editData, setEditData] = useState({
    id: '',
    name: '',
    email: '',
    uid: '',
    password: '',
    subscription_status: 'trial' as 'trial' | 'active',
    trial_expires_at: ''
  });

  useEffect(() => {
    const q = query(collection(db, 'branches'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const branchesData: BranchInfo[] = [];
      snapshot.forEach((doc) => {
        branchesData.push({ id: doc.id, ...doc.data() } as BranchInfo);
      });
      setBranches(branchesData);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  // Fetch provinces when create modal opens
  useEffect(() => {
    if (isModalOpen && provinces.length === 0) {
      setLoadingProvinces(true);
      fetch('https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json')
        .then(res => res.json())
        .then(data => setProvinces(data))
        .catch(err => console.error(err))
        .finally(() => setLoadingProvinces(false));
    }
  }, [isModalOpen, provinces.length]);

  // Fetch cities when province changes
  useEffect(() => {
    if (formData.provinceId) {
      setLoadingCities(true);
      fetch(`https://www.emsifa.com/api-wilayah-indonesia/api/regencies/${formData.provinceId}.json`)
        .then(res => res.json())
        .then(data => setCities(data))
        .catch(err => console.error(err))
        .finally(() => setLoadingCities(false));
    } else {
      setCities([]);
    }
  }, [formData.provinceId]);


  const handleSubmitCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.provinceName || !formData.cityName) {
      alert("Harap lengkapi semua kolom termasuk provinsi dan kota!");
      return;
    }
    setIsSubmitting(true);
    
    const finalProvinceId = formatId(formData.provinceName);
    const finalCityId = formatId(formData.cityName);
    
    const res = await createBranchAccount({
      name: formData.name,
      email: formData.email,
      password: formData.password,
      provinceId: finalProvinceId,
      cityId: finalCityId,
    });
    setIsSubmitting(false);

    if (res.success) {
      setIsModalOpen(false);
      setFormData({ name: '', email: '', password: '', provinceId: '', provinceName: '', cityId: '', cityName: '' });
    } else {
      alert('Gagal mendaftar: ' + res.error);
    }
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    const res = await updateBranch(editData.id, editData.name, editData.uid, editData.password, editData.email);
    
    if (res.success) {
      await updateSubscriptionStatus(
        editData.id, 
        editData.uid, 
        editData.subscription_status,
        editData.trial_expires_at
      );
    }

    setIsSubmitting(false);
    
    if (res.success) {
      setIsEditModalOpen(false);
      alert('Cabang berhasil diupdate!');
    } else {
      alert('Gagal update: ' + res.error);
    }
  };

  const handleToggleStatus = async (b: BranchInfo) => {
    const isCurrentlyActive = b.isActive !== false;
    const actionName = isCurrentlyActive ? 'Nonaktifkan' : 'Aktifkan';
    
    if (confirm(`Apakah Anda yakin ingin ${actionName} akses cabang ${b.name}?`)) {
      const res = await toggleBranchStatus(b.uid, b.id, isCurrentlyActive);
      if (!res.success) {
        alert('Gagal mengubah status: ' + res.error);
      }
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setIsSubmitting(true);
    const res = await deleteBranch(deleteTarget.id, deleteTarget.uid);
    setIsSubmitting(false);
    
    if (res.success) {
      setDeleteTarget(null);
    } else {
      alert('Gagal menghapus cabang: ' + res.error);
    }
  };

  const openEdit = (b: BranchInfo) => {
    setEditData({ 
      id: b.id, 
      name: b.name, 
      email: b.email || '', 
      uid: b.uid, 
      password: '',
      subscription_status: b.subscription_status || 'trial',
      trial_expires_at: b.trial_expires_at || ''
    });
    setIsEditModalOpen(true);
  };

  const availableProvinces = Array.from(new Set(branches.map(b => b.provinceId).filter(Boolean))) as string[];
  const availableCities = filterProvince 
    ? Array.from(new Set(branches.filter(b => b.provinceId === filterProvince).map(b => b.cityId).filter(Boolean))) as string[]
    : [];

  const filteredBranches = branches.filter(b => {
    if (filterName && !b.name.toLowerCase().includes(filterName.toLowerCase())) return false;
    if (filterProvince && b.provinceId !== filterProvince) return false;
    if (filterCity && b.cityId !== filterCity) return false;
    return true;
  });

  if (loading) return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat data cabang...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '8px'}}>Manajemen Cabang</h1>
          <p style={{color: 'var(--text-muted)'}}>
            Kelola daftar cabang, status aktif, dan pengaturan toko.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setIsModalOpen(true)}>
          + Tambah Cabang
        </button>
      </div>

      <div className="card" style={{ overflowX: 'auto' }}>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '16px', flexWrap: 'wrap' }}>
          <div style={{ flex: '1', minWidth: '200px' }}>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px', color: 'var(--text-muted)'}}>Cari Cabang</label>
            <input 
              type="text"
              className="input-field"
              placeholder="Ketik nama cabang..."
              value={filterName}
              onChange={(e) => setFilterName(e.target.value)}
            />
          </div>
          <div style={{ flex: '1', minWidth: '200px' }}>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px', color: 'var(--text-muted)'}}>Filter Provinsi</label>
            <select 
              className="input-field"
              value={filterProvince}
              onChange={(e) => {
                setFilterProvince(e.target.value);
                setFilterCity(''); // Reset city when province changes
              }}
            >
              <option value="">Semua Provinsi</option>
              {availableProvinces.map(p => (
                <option key={p} value={p}>{p.replace(/_/g, ' ').toUpperCase()}</option>
              ))}
            </select>
          </div>
          <div style={{ flex: '1', minWidth: '200px' }}>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px', color: 'var(--text-muted)'}}>Filter Kota/Kabupaten</label>
            <select 
              className="input-field"
              value={filterCity}
              onChange={(e) => setFilterCity(e.target.value)}
              disabled={!filterProvince}
            >
              <option value="">{filterProvince ? 'Semua Kota' : 'Pilih Provinsi Dahulu'}</option>
              {availableCities.map(c => (
                <option key={c} value={c}>{c.replace(/_/g, ' ').toUpperCase()}</option>
              ))}
            </select>
          </div>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid var(--surface-border)', textAlign: 'left' }}>
              <th style={{ padding: '16px 12px', color: 'var(--text-muted)', fontWeight: '600' }}>Nama Cabang</th>
              <th style={{ padding: '16px 12px', color: 'var(--text-muted)', fontWeight: '600' }}>Email POS</th>
              <th style={{ padding: '16px 12px', color: 'var(--text-muted)', fontWeight: '600' }}>Lokasi (ID)</th>
              <th style={{ padding: '16px 12px', color: 'var(--text-muted)', fontWeight: '600', textAlign: 'center' }}>Status</th>
              <th style={{ padding: '16px 12px', color: 'var(--text-muted)', fontWeight: '600', textAlign: 'right' }}>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {filteredBranches.map((b) => {
              const isActive = b.isActive !== false;
              return (
                <tr key={b.id} style={{ borderBottom: '1px solid var(--surface-border)' }}>
                  <td style={{ padding: '16px 12px', fontWeight: 600 }}>{b.name}</td>
                  <td style={{ padding: '16px 12px', color: 'var(--text-muted)' }}>{b.email || '-'}</td>
                  <td style={{ padding: '16px 12px', color: '#64748b' }}>
                    {b.provinceId ? (
                      <>
                        <div style={{ fontSize: '12px' }}>P: {b.provinceId}</div>
                        <div style={{ fontSize: '12px' }}>K: {b.cityId}</div>
                      </>
                    ) : (
                      <div style={{ fontSize: '12px', fontStyle: 'italic' }}>Tidak ada data</div>
                    )}
                  </td>
                  <td style={{ padding: '16px 12px', textAlign: 'center' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', alignItems: 'center' }}>
                      <span style={{
                        padding: '4px 10px',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        background: isActive ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)',
                        color: isActive ? '#10b981' : '#ef4444'
                      }}>
                        {isActive ? 'Login Aktif' : 'Login Nonaktif'}
                      </span>
                      <span style={{
                        padding: '4px 10px',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        background: b.subscription_status === 'active' ? 'rgba(59, 130, 246, 0.15)' : 'rgba(245, 158, 11, 0.15)',
                        color: b.subscription_status === 'active' ? '#3b82f6' : '#f59e0b'
                      }}>
                        {b.subscription_status === 'active' ? 'Pro' : 'Trial'}
                      </span>
                      {b.subscription_status !== 'active' && b.trial_expires_at && (
                        <Countdown expiresAt={b.trial_expires_at} />
                      )}
                    </div>
                  </td>
                  <td style={{ padding: '16px 12px', textAlign: 'right' }}>
                    <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                      <button 
                        onClick={() => openEdit(b)}
                        style={{ padding: '6px 12px', background: 'transparent', border: '1px solid var(--primary)', color: 'var(--primary)', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', fontWeight: '500' }}>
                        Edit
                      </button>
                      <button 
                        onClick={() => handleToggleStatus(b)}
                        style={{ padding: '6px 12px', background: 'transparent', border: `1px solid ${isActive ? '#f59e0b' : '#10b981'}`, color: isActive ? '#f59e0b' : '#10b981', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', fontWeight: '500' }}>
                        {isActive ? 'Suspend' : 'Aktifkan'}
                      </button>
                      <button 
                        onClick={() => setDeleteTarget(b)}
                        style={{ padding: '6px 12px', background: 'var(--danger)', border: 'none', color: 'white', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', fontWeight: '500' }}>
                        Hapus
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
            {filteredBranches.length === 0 && (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  Tidak ada cabang yang sesuai.
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
          backgroundColor: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)', zIndex: 100,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div className="card" style={{ width: '100%', maxWidth: '500px', maxHeight: '90vh', overflowY: 'auto' }}>
            <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '8px'}}>Tambah Cabang Baru</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: '24px', fontSize: '13px' }}>
              Mendaftarkan toko/cabang baru ke dalam database.
            </p>
            <form onSubmit={handleSubmitCreate} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Toko / Cabang</label>
                <input 
                  type="text" className="input-field" required 
                  placeholder="misal: Kasir Digital Cabang Sudirman"
                  value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} 
                />
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Provinsi</label>
                <select 
                  className="input-field"
                  required 
                  value={formData.provinceId} 
                  onChange={(e) => {
                    const selected = provinces.find(p => p.id === e.target.value);
                    setFormData({ ...formData, provinceId: selected?.id || '', provinceName: selected?.name || '', cityId: '', cityName: '' });
                  }}
                  disabled={loadingProvinces}
                >
                  <option value="">{loadingProvinces ? 'Memuat Provinsi...' : '-- Pilih Provinsi --'}</option>
                  {provinces.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Kota / Kabupaten</label>
                <select 
                  className="input-field"
                  required 
                  value={formData.cityId} 
                  onChange={(e) => {
                    const selected = cities.find(c => c.id === e.target.value);
                    setFormData({ ...formData, cityId: selected?.id || '', cityName: selected?.name || '' });
                  }}
                  disabled={!formData.provinceId || loadingCities}
                >
                  <option value="">
                    {!formData.provinceId ? 'Pilih provinsi terlebih dahulu' : (loadingCities ? 'Memuat Kota...' : '-- Pilih Kota --')}
                  </option>
                  {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>

              <div style={{ height: '1px', background: 'var(--surface-border)', margin: '4px 0' }}></div>
              <p style={{ fontSize: '13px', color: 'var(--primary)', fontWeight: '500', margin: 0 }}>Akun Mesin Kasir (POS):</p>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login Aplikasi</label>
                <input 
                  type="email" className="input-field" required 
                  placeholder="misal: kasir.sudirman@toko.com"
                  value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value.toLowerCase()})} 
                />
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password</label>
                <input 
                  type="password" className="input-field" required 
                  placeholder="Minimal 6 karakter"
                  value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})} 
                />
              </div>
              
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} style={{ background: 'var(--surface)', border: '1px solid var(--surface-border)', color: 'var(--text-main)', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer', fontWeight: 500 }}>
                  Batal
                </button>
                <button type="submit" className="btn-primary" disabled={isSubmitting || !formData.name || !formData.provinceName || !formData.cityName}>
                  {isSubmitting ? 'Mendaftarkan...' : 'Simpan Cabang'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Edit Cabang */}
      {isEditModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          backgroundColor: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)', zIndex: 100,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div className="card" style={{ width: '100%', maxWidth: '400px' }}>
            <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '8px'}}>Edit Cabang</h2>
            <form onSubmit={handleEditSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Toko / Cabang</label>
                <input 
                  type="text" className="input-field" required 
                  value={editData.name} onChange={(e) => setEditData({...editData, name: e.target.value})} 
                />
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login (Aplikasi Kasir)</label>
                <input 
                  type="email" className="input-field" required 
                  value={editData.email} onChange={(e) => setEditData({...editData, email: e.target.value.toLowerCase()})} 
                />
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password Baru (Opsional)</label>
                <input 
                  type="password" className="input-field" 
                  placeholder="Kosongkan jika tidak ingin ganti password"
                  value={editData.password} onChange={(e) => setEditData({...editData, password: e.target.value})} 
                />
              </div>

              <div style={{ padding: '16px', background: 'var(--surface-hover)', borderRadius: '8px', marginTop: '8px' }}>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Status Langganan</label>
                <select 
                  className="input-field"
                  value={editData.subscription_status}
                  onChange={(e) => setEditData({...editData, subscription_status: e.target.value as 'trial'|'active'})}
                  style={{ marginBottom: editData.subscription_status === 'trial' ? '12px' : '0' }}
                >
                  <option value="trial">Trial (Batas Waktu)</option>
                  <option value="active">Active (Pro / Tanpa Batas)</option>
                </select>
                
                {editData.subscription_status === 'trial' && (
                  <div style={{ marginTop: '8px' }}>
                    <label style={{display: 'block', marginBottom: '4px', fontWeight: '500', fontSize: '12px'}}>Batas Waktu Trial</label>
                    <input 
                      type="datetime-local" 
                      className="input-field" 
                      style={{ fontSize: '13px', padding: '8px', cursor: 'pointer' }}
                      onClick={(e) => {
                        try {
                          (e.target as HTMLInputElement).showPicker();
                        } catch (err) {} 
                      }}
                      value={editData.trial_expires_at ? new Date(editData.trial_expires_at).toLocaleString('sv-SE', { timeZoneName: 'short' }).substring(0, 16).replace(' ', 'T') : ''} 
                      onChange={(e) => {
                        if (e.target.value) {
                          const date = new Date(e.target.value);
                          setEditData({...editData, trial_expires_at: date.toISOString()});
                        }
                      }}
                    />
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
                <button type="button" onClick={() => setIsEditModalOpen(false)} style={{ background: 'var(--surface)', border: '1px solid var(--surface-border)', color: 'var(--text-main)', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer', fontWeight: 500 }}>
                  Batal
                </button>
                <button type="submit" className="btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Menyimpan...' : 'Update Cabang'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Konfirmasi Delete Permanen */}
      {deleteTarget && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          backgroundColor: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)', zIndex: 100,
          display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px'
        }}>
          <div className="card" style={{ width: '100%', maxWidth: '450px', borderTop: '4px solid var(--danger)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ background: '#fee2e2', padding: '12px', borderRadius: '50%', color: '#dc2626' }}>
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
              </div>
              <h2 style={{fontSize: '20px', fontWeight: 'bold', color: 'var(--danger)', margin: 0}}>Hapus Permanen?</h2>
            </div>
            
            <p style={{ color: 'var(--text-main)', marginBottom: '12px', fontSize: '15px', lineHeight: '1.5' }}>
              Anda akan menghapus cabang <strong>{deleteTarget.name}</strong> secara permanen.
            </p>
            
            <div style={{ background: '#fef2f2', border: '1px solid #fecaca', padding: '16px', borderRadius: '8px', marginBottom: '24px' }}>
              <p style={{ color: '#991b1b', fontSize: '13px', margin: 0, lineHeight: '1.5', fontWeight: '500' }}>
                <strong>PERINGATAN:</strong> Tindakan ini akan menghapus akses login aplikasi, PIN, dan profil cabang secara permanen. Anda tidak bisa mengembalikan data ini.
                Jika cabang hanya tutup sementara, gunakan fitur <strong>Suspend (Nonaktif)</strong> saja!
              </p>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button 
                type="button" 
                onClick={() => setDeleteTarget(null)} 
                style={{ background: 'var(--surface)', border: '1px solid var(--surface-border)', color: 'var(--text-main)', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 600 }}>
                Batal
              </button>
              <button 
                type="button" 
                onClick={handleDelete}
                disabled={isSubmitting}
                style={{ background: 'var(--danger)', border: 'none', color: 'white', padding: '10px 20px', borderRadius: '8px', cursor: isSubmitting ? 'not-allowed' : 'pointer', fontWeight: 600 }}>
                {isSubmitting ? 'Menghapus...' : 'Ya, Hapus Permanen!'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
