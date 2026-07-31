'use client';

import Link from 'next/link';
import styles from './layout.module.css';
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className={`${styles.dashboardContainer} ${inter.className}`}>
      {/* Sidebar */}
      <aside className={styles.sidebar}>
        <div className={styles.logo}>
          <h2>Kasir Digital</h2>
          <span className={styles.badge}>Superadmin</span>
        </div>
        
        <nav className={styles.nav}>
          <Link href="/dashboard" className={styles.navItem}>
            <span className={styles.icon}>📊</span>
            Ringkasan
          </Link>
          <Link href="/dashboard/karyawan" className={styles.navItem}>
            <span className={styles.icon}>👥</span>
            Kelola Karyawan
          </Link>
          <Link href="/dashboard/cabang" className={styles.navItem}>
            <span className={styles.icon}>🏬</span>
            Cabang / Kota
          </Link>
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
