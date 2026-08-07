'use client';

import { useEffect, useState } from 'react';
import { collection, getCountFromServer } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export default function DashboardSummary() {
  const [metrics, setMetrics] = useState({ branches: 0, sysStatus: 'Memuat...' });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadMetrics() {
      try {
        // Hitung Cabang (dari collection branches)
        const branchSnap = await getCountFromServer(collection(db, 'branches'));
        const totalBranches = branchSnap.data().count;

        setMetrics({
          branches: totalBranches,
          sysStatus: 'Superadmin Pro'
        });
      } catch (err) {
        console.error("Gagal memuat metrik:", err);
      } finally {
        setLoading(false);
      }
    }

    loadMetrics();
  }, []);

  if (loading) {
    return <div style={{padding: '40px'}}>Memuat data dari database...</div>;
  }

  return (
    <div>
      <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '24px'}}>Ringkasan Sistem</h1>
      
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '24px'}}>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Cabang Aktif</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--primary)'}}>{metrics.branches}</p>
        </div>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Lisensi Sistem</h3>
          <p style={{fontSize: '28px', fontWeight: 'bold', color: 'var(--accent, #6366f1)'}}>{metrics.sysStatus}</p>
        </div>

      </div>

      <div className="card" style={{marginTop: '40px'}}>
        <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '16px'}}>Selamat Datang, Superadmin!</h2>
        <p style={{color: 'var(--text-muted)'}}>
          Anda berada di Pusat Kendali Web Admin. Gunakan menu di sebelah kiri untuk mengelola Cabang dan PIN akses mesin kasir di seluruh jaringan Kasir Digital.
        </p>
      </div>
    </div>
  );
}
