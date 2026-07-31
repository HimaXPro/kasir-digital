export default function DashboardSummary() {
  return (
    <div>
      <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '24px'}}>Ringkasan Sistem</h1>
      
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '24px'}}>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Cabang Aktif</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--primary)'}}>4</p>
        </div>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Karyawan</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--primary)'}}>12</p>
        </div>
        
        <div className="card">
          <h3 style={{color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px'}}>Total Transaksi Hari Ini</h3>
          <p style={{fontSize: '32px', fontWeight: 'bold', color: 'var(--accent)'}}>145</p>
        </div>

      </div>

      <div className="card" style={{marginTop: '40px'}}>
        <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '16px'}}>Selamat Datang, Superadmin!</h2>
        <p style={{color: 'var(--text-muted)'}}>
          Anda berada di Pusat Kendali Web Admin. Gunakan menu di sebelah kiri untuk mengelola Cabang dan Karyawan di seluruh jaringan Kasir Digital.
        </p>
      </div>
    </div>
  );
}
