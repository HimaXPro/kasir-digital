'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { doc, getDoc, setDoc } from 'firebase/firestore';

interface AppConfig {
  minimum_version: number;
  latest_version: number;
  update_url: string;
  is_maintenance: boolean;
  maintenance_message: string;
  is_scheduled: boolean;
  maintenance_start: string;
  maintenance_end: string;
}

export default function PengaturanPage() {
  const [config, setConfig] = useState<AppConfig>({
    minimum_version: 1,
    latest_version: 1,
    update_url: 'https://play.google.com/store/apps/details?id=com.himaxpro.kasirdigital',
    is_maintenance: false,
    maintenance_message: 'Sistem sedang dalam perbaikan rutin. Silakan coba kembali dalam beberapa saat.',
    is_scheduled: false,
    maintenance_start: '',
    maintenance_end: '',
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
          const data = docSnap.data();
          setConfig(prev => ({ ...prev, ...data }));
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

          <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', margin: '16px 0' }}></div>

          <div>
            <h2 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '8px', color: '#F59E0B' }}>Mode Pemeliharaan (Maintenance)</h2>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>
              Nyalakan saklar ini untuk mengunci seluruh aplikasi kasir secara instan saat ada perbaikan sistem.
            </p>
            
            <label style={{ display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer', marginBottom: '16px' }}>
              <div style={{
                width: '44px',
                height: '24px',
                backgroundColor: config.is_maintenance ? '#EF4444' : 'rgba(255,255,255,0.2)',
                borderRadius: '24px',
                position: 'relative',
                transition: 'background-color 0.3s'
              }}>
                <div style={{
                  width: '20px',
                  height: '20px',
                  backgroundColor: 'white',
                  borderRadius: '50%',
                  position: 'absolute',
                  top: '2px',
                  left: config.is_maintenance ? '22px' : '2px',
                  transition: 'left 0.3s',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
                }}></div>
              </div>
              <input 
                type="checkbox"
                style={{ display: 'none' }}
                checked={config.is_maintenance || false}
                onChange={(e) => setConfig({...config, is_maintenance: e.target.checked})}
              />
              <span style={{ fontSize: '14px', fontWeight: '600', color: config.is_maintenance ? '#EF4444' : 'var(--text-muted)' }}>
                {config.is_maintenance ? 'Maintenance AKTIF (Kasir Diblokir)' : 'Maintenance Mati (Normal)'}
              </span>
            </label>

            <label style={{ display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer', marginBottom: '16px' }}>
              <div style={{
                width: '44px',
                height: '24px',
                backgroundColor: config.is_scheduled ? '#3B82F6' : 'rgba(255,255,255,0.2)',
                borderRadius: '24px',
                position: 'relative',
                transition: 'background-color 0.3s'
              }}>
                <div style={{
                  width: '20px',
                  height: '20px',
                  backgroundColor: 'white',
                  borderRadius: '50%',
                  position: 'absolute',
                  top: '2px',
                  left: config.is_scheduled ? '22px' : '2px',
                  transition: 'left 0.3s',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
                }}></div>
              </div>
              <input 
                type="checkbox"
                style={{ display: 'none' }}
                checked={config.is_scheduled || false}
                onChange={(e) => setConfig({...config, is_scheduled: e.target.checked})}
              />
              <span style={{ fontSize: '14px', fontWeight: '600', color: config.is_scheduled ? '#3B82F6' : 'var(--text-muted)' }}>
                {config.is_scheduled ? 'Jadwal Otomatis AKTIF' : 'Jadwal Otomatis Mati'}
              </span>
            </label>

            {config.is_scheduled && (
              <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Waktu Mulai</label>
                  <input 
                    type="datetime-local"
                    className="input-field"
                    value={config.maintenance_start}
                    onChange={(e) => setConfig({...config, maintenance_start: e.target.value})}
                    required={config.is_scheduled}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Waktu Selesai</label>
                  <input 
                    type="datetime-local"
                    className="input-field"
                    value={config.maintenance_end}
                    onChange={(e) => setConfig({...config, maintenance_end: e.target.value})}
                    required={config.is_scheduled}
                  />
                </div>
              </div>
            )}

            {(config.is_maintenance || config.is_scheduled) && (
              <div style={{ marginTop: '12px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Pesan Maintenance</label>
                <textarea 
                  className="input-field"
                  style={{ minHeight: '80px', resize: 'vertical' }}
                  value={config.maintenance_message}
                  onChange={(e) => setConfig({...config, maintenance_message: e.target.value})}
                  placeholder="Contoh: Sistem sedang di-update, mohon tunggu 30 menit."
                />
              </div>
            )}
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
