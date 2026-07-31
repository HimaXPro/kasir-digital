'use client';

import { useEffect, useState } from 'react';
import { collection, getCountFromServer, query, where, getDocs } from 'firebase/firestore';
import { db, auth } from '@/lib/firebase';

export default function DashboardSummary() {
  const [metrics, setMetrics] = useState({ branches: 0, employees: 0, todayTrx: 0 });
  const [loading, setLoading] = useState(true);
  const [userName, setUserName] = useState('Memuat...');
  const [role, setRole] = useState('');

  useEffect(() => {
    async function loadMetrics() {
      try {
        const user = auth.currentUser;
        if (!user) return;
        
        // Cek role dari database
        const userDocRef = await getDocs(query(collection(db, 'users'), where('email', '==', user.email)));
        let currentRole = 'admin';
        let cityId = '';
        if (!userDocRef.empty) {
          const uData = userDocRef.docs[0].data();
          setUserName(uData.name || 'Admin');
          currentRole = uData.role || 'admin';
          cityId = uData.city_id || '';
          setRole(currentRole);
        }

        // Hitung Karyawan
        let empQuery = collection(db, 'users');
        if (currentRole !== 'superadmin' && cityId) {
          empQuery = query(collection(db, 'users'), where('city_id', '==', cityId)) as any;
        }
        const empSnap = await getCountFromServer(empQuery);
        const totalEmployees = empSnap.data().count;

        // Hitung Cabang (Cities) - disederhanakan dengan mengambil daftar city unik dari users
        // Untuk superadmin, kita bisa hitung jumlah kota unik
        let totalBranches = 1; 
        if (currentRole === 'superadmin') {
           const allUsers = await getDocs(collection(db, 'users'));
           const cities = new Set(allUsers.docs.map(d => d.data().city_id).filter(Boolean));
           totalBranches = cities.size;
        }

        // Transaksi Hari ini (Mock dulu sebelum index disiapkan)
        // Jika owner, ambil transaksi dari kotanya
        let todayTrx = 0;
        if (cityId) {
          const trxRef = collection(db, 'provinces', 'jatim', 'cities', cityId, 'transactions');
          // Karena query tanggal butuh composite index, kita hitung semua dulu atau pakai getCount
          const trxSnap = await getCountFromServer(trxRef);
          todayTrx = trxSnap.data().count; 
        }

        setMetrics({
          branches: totalBranches,
          employees: totalEmployees,
          todayTrx: todayTrx
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
        
        {role === 'superadmin' && (
          <div className="card">
            <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Cabang Aktif</h3>
            <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--primary)'}}>{metrics.branches}</p>
          </div>
        )}
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Karyawan</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--primary)'}}>{metrics.employees}</p>
        </div>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Transaksi (Semua Waktu)</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--accent)'}}>{metrics.todayTrx}</p>
        </div>

      </div>

      <div className="card" style={{marginTop: '40px'}}>
        <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '16px'}}>Selamat Datang, {userName}!</h2>
        <p style={{color: 'var(--text-muted)'}}>
          Anda berada di Pusat Kendali Web Admin. Gunakan menu di sebelah kiri untuk mengelola Cabang dan Karyawan di seluruh jaringan Kasir Digital.
        </p>
      </div>
    </div>
  );
}
