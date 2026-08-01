'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import styles from './layout.module.css';
import { Inter } from 'next/font/google';
import { auth, db } from '@/lib/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

const inter = Inter({ subsets: ['latin'] });

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [role, setRole] = useState('');
  const [title, setTitle] = useState('Memuat...');
  const [loading, setLoading] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (user) => {
      if (user) {
        // Cek sesi 24 jam
        const loginTime = localStorage.getItem('loginTimestamp');
        if (loginTime) {
          const diff = Date.now() - parseInt(loginTime);
          if (diff >= 24 * 60 * 60 * 1000) { // 24 jam
            await auth.signOut();
            localStorage.removeItem('loginTimestamp');
            window.location.href = '/login';
            return;
          }
        }

        const userDocRef = await getDocs(query(collection(db, 'users'), where('email', '==', user.email)));
        if (!userDocRef.empty) {
          const uData = userDocRef.docs[0].data();
          setRole(uData.role);
          setTitle(uData.role === 'superadmin' ? 'Superadmin' : 'Admin Cabang');
        }
        setLoading(false);
      } else {
        // Redirect to login if user is not authenticated
        window.location.href = '/login';
      }
    });
    return () => unsubscribe();
  }, []);

  if (loading) {
    return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat antarmuka...</div>;
  }

  return (
    <div className={`${styles.dashboardContainer} ${inter.className}`}>
      
      {/* Mobile Topbar */}
      <div className={styles.mobileTopbar}>
        <div className={styles.logoMobile}>
          <h2>Kasir Digital</h2>
        </div>
        <button 
          className={styles.menuToggle} 
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
        >
          ☰
        </button>
      </div>

      {/* Overlay for mobile sidebar */}
      {isMobileMenuOpen && (
        <div 
          className={styles.mobileOverlay} 
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`${styles.sidebar} ${isMobileMenuOpen ? styles.sidebarOpen : ''}`}>
        <div className={styles.logo}>
          <h2>Kasir Digital</h2>
          <span className={styles.badge}>{title}</span>
        </div>
        
        <nav className={styles.nav}>
          <Link href="/dashboard" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
            <span className={styles.icon}>📊</span>
            Ringkasan
          </Link>
          <Link href="/dashboard/karyawan" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
            <span className={styles.icon}>👥</span>
            Kelola Karyawan
          </Link>
          {role === 'superadmin' && (
            <Link href="/dashboard/cabang" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
              <span className={styles.icon}>🏬</span>
              Cabang / Kota
            </Link>
          )}
        </nav>
        
        <div className={styles.logoutBtn}>
          <button className="btn-primary" style={{width: '100%', background: 'var(--danger)'}} onClick={() => {
            // Need a client component to handle logout, simplified here for layout
            window.location.href = '/login';
          }}>
            Keluar
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className={styles.mainContent}>
        {children}
      </main>
    </div>
  );
}
