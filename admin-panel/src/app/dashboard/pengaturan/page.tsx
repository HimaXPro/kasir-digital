'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { doc, getDoc, setDoc } from 'firebase/firestore';

interface AppConfig {
  minimum_version: number;
  latest_version: number;
  update_url: string;
}

export default function PengaturanPage() {
  const [config, setConfig] = useState<AppConfig>({
    minimum_version: 1,
    latest_version: 1,
    update_url: 'https://play.google.com/store/apps/details?id=com.himaxpro.kasirdigital',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ text: '', type: '' });

  useEffect(() => {
    async function loadConfig() {
      try {
        const docRef = doc(db, 'settings', 'app_config');
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          setConfig(docSnap.data() as AppConfig);
        }
      } catch (err) {
        console.error('Gagal memuat pengaturan', err);
      } finally {
        setLoading(false);
      }
    }
    loadConfig();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage({ text: '', type: '' });

    try {
      await setDoc(doc(db, 'settings', 'app_config'), config);
      setMessage({ text: 'Pengaturan berhasil disimpan!', type: 'success' });
    } catch (err) {
      console.error(err);
      setMessage({ text: 'Gagal menyimpan pengaturan.', type: 'error' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div style={{ padding: '40px' }}>Memuat pengaturan...</div>;
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>Pengaturan Aplikasi</h1>
      </div>

      <div className="card" style={{ maxWidth: '600px' }}>
        <h2 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '8px' }}>Notifikasi Update Paksa (Force Update)</h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '24px' }}>
          Atur versi minimum yang diizinkan untuk mengakses aplikasi Kasir Mobile. Jika versi aplikasi kasir berada di bawah versi minimum ini, mereka akan dipaksa untuk memperbarui aplikasi.
        </p>

        {message.text && (
          <div style={{ 
            padding: '12px 16px', 
            borderRadius: '8px', 
            marginBottom: '20px', 
            backgroundColor: message.type === 'success' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
            color: message.type === 'success' ? '#10B981' : '#EF4444',
            border: `1px solid ${message.type === 'success' ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`
          }}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Versi Minimum (Force Update)</label>
            <input 
              type="number"
              className="input-field"
              value={config.minimum_version}
              onChange={(e) => setConfig({...config, minimum_version: parseInt(e.target.value) || 1})}
              required
            />
            <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Aplikasi dengan versi di bawah angka ini tidak akan bisa digunakan (diblokir).</p>
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Versi Terbaru (Opsional Update)</label>
            <input 
              type="number"
              className="input-field"
              value={config.latest_version}
              onChange={(e) => setConfig({...config, latest_version: parseInt(e.target.value) || 1})}
              required
            />
            <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Jika aplikasi kasir di atas minimum tapi di bawah versi terbaru ini, hanya muncul notifikasi opsional.</p>
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Link Update / Play Store</label>
            <input 
              type="url"
              className="input-field"
              value={config.update_url}
              onChange={(e) => setConfig({...config, update_url: e.target.value})}
              required
            />
          </div>

          <div style={{ marginTop: '12px' }}>
            <button type="submit" className="btn-primary" disabled={saving}>
              {saving ? 'Menyimpan...' : 'Simpan Pengaturan'}
            </button>
          </div>
          
        </form>
      </div>
    </div>
  );
}
