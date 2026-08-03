'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { createBranchAccount } from '@/app/actions/branchActions';

interface BranchInfo {
  id: string;
  name: string;
  provinceId: string;
  cityId: string;
}

interface Region {
  id: string;
  name: string;
}

const formatId = (name: string) => {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
};

export default function CabangPage() {
  const [branches, setBranches] = useState<BranchInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Region Data
  const [provinces, setProvinces] = useState<Region[]>([]);
  const [cities, setCities] = useState<Region[]>([]);
  const [loadingProvinces, setLoadingProvinces] = useState(false);
  const [loadingCities, setLoadingCities] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    provinceId: '', // We will store the original ID from API temporarily to fetch cities
    provinceName: '',
    cityId: '',
    cityName: '',
  });

  useEffect(() => {
    // Fetch from 'branches' collection
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

  // Fetch provinces when modal opens
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.provinceName || !formData.cityName) {
      alert("Harap pilih provinsi dan kota!");
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
      alert('Cabang berhasil didaftarkan!');
      setIsModalOpen(false);
      setFormData({ name: '', email: '', password: '', provinceId: '', provinceName: '', cityId: '', cityName: '' });
    } else {
      alert('Gagal mendaftar: ' + res.error);
    }
  };

  const handleProvinceChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selected = provinces.find(p => p.id === e.target.value);
    setFormData({
      ...formData,
      provinceId: selected?.id || '',
      provinceName: selected?.name || '',
      cityId: '',
      cityName: ''
    });
  };

  const handleCityChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selected = cities.find(c => c.id === e.target.value);
    setFormData({
      ...formData,
      cityId: selected?.id || '',
      cityName: selected?.name || ''
    });
  };

  if (loading) return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat data cabang...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '8px'}}>Manajemen Cabang</h1>
          <p style={{color: 'var(--text-muted)'}}>
            Daftar cabang/toko yang terdaftar di sistem pusat.
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
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>Email Login POS</th>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>ID Provinsi</th>
              <th style={{ padding: '12px 8px', color: 'var(--text-muted)', fontWeight: '600' }}>ID Kota</th>
            </tr>
          </thead>
          <tbody>
            {branches.map((b) => (
              <tr key={b.id} style={{ borderBottom: '1px solid #eaeaea' }}>
                <td style={{ padding: '12px 8px', fontWeight: 600 }}>{b.name}</td>
                <td style={{ padding: '12px 8px', color: 'var(--text-muted)' }}>{(b as any).email || '-'}</td>
                <td style={{ padding: '12px 8px', color: '#64748b' }}>{b.provinceId}</td>
                <td style={{ padding: '12px 8px', color: '#64748b' }}>{b.cityId}</td>
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
              Mendaftarkan struktur cabang baru ke dalam database.
            </p>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              
              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Provinsi</label>
                <select 
                  className="input-field"
                  required 
                  value={formData.provinceId} 
                  onChange={handleProvinceChange}
                  disabled={loadingProvinces}
                >
                  <option value="">{loadingProvinces ? 'Memuat Provinsi...' : '-- Pilih Provinsi --'}</option>
                  {provinces.map(p => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Kota / Kabupaten</label>
                <select 
                  className="input-field"
                  required 
                  value={formData.cityId} 
                  onChange={handleCityChange}
                  disabled={!formData.provinceId || loadingCities}
                >
                  <option value="">
                    {!formData.provinceId 
                      ? 'Pilih provinsi terlebih dahulu' 
                      : (loadingCities ? 'Memuat Kota...' : '-- Pilih Kota --')}
                  </option>
                  {cities.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Toko / Cabang</label>
                <input 
                  type="text" 
                  className="input-field"
                  required 
                  placeholder="misal: Kasir Digital Cabang Sudirman"
                  value={formData.name} 
                  onChange={(e) => setFormData({...formData, name: e.target.value})} 
                />
              </div>

              <div style={{ height: '1px', background: 'var(--surface-border)', margin: '4px 0' }}></div>
              <p style={{ fontSize: '13px', color: 'var(--primary)', fontWeight: '500', margin: 0 }}>Akun Mesin Kasir (POS):</p>

              <div>
                <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login Aplikasi</label>
                <input 
                  type="email" 
                  className="input-field"
                  required 
                  placeholder="misal: kasir.sudirman@toko.com"
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
                  placeholder="Minimal 6 karakter"
                  value={formData.password} 
                  onChange={(e) => setFormData({...formData, password: e.target.value})} 
                />
              </div>
              
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} style={{ background: 'transparent', border: '1px solid #ddd', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer', fontWeight: 500 }}>
                  Batal
                </button>
                <button type="submit" className="btn-primary" disabled={isSubmitting || !formData.provinceName || !formData.cityName}>
                  {isSubmitting ? 'Mendaftarkan...' : 'Simpan Cabang'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
