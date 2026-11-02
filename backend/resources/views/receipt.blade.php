<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Struk Thermal - {{ $order->code }}</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Courier New', Courier, monospace;
            font-size: 12px;
            color: #000;
            background: #f1f5f9;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .actions {
            margin-bottom: 16px;
            display: flex;
            gap: 10px;
        }
        .actions button {
            background: #059669;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-family: inherit;
            font-weight: bold;
            font-size: 13px;
        }
        .actions button.btn-secondary {
            background: #475569;
        }
        .receipt-container {
            width: 58mm;
            max-width: 100%;
            background: #fff;
            padding: 12px 10px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .receipt-container.w-80 {
            width: 80mm;
            padding: 16px 14px;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .text-left { text-align: left; }
        .bold { font-weight: bold; }
        .store-name {
            font-size: 16px;
            font-weight: 900;
            letter-spacing: 1px;
            margin-bottom: 2px;
        }
        .store-sub {
            font-size: 10px;
            margin-bottom: 6px;
        }
        .dashed {
            border-top: 1px dashed #000;
            margin: 8px 0;
        }
        .double-dashed {
            border-top: 2px dashed #000;
            margin: 8px 0;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            margin-bottom: 3px;
        }
        .item-table {
            width: 100%;
            font-size: 11px;
            border-collapse: collapse;
        }
        .item-table td {
            vertical-align: top;
            padding: 2px 0;
        }
        .total-row {
            display: flex;
            justify-content: space-between;
            font-size: 11.5px;
            margin-bottom: 3px;
        }
        .grand-total {
            font-size: 14px;
            font-weight: 900;
            margin-top: 4px;
        }
        .footer {
            font-size: 10px;
            margin-top: 10px;
            line-height: 1.3;
        }
        @media print {
            body {
                background: none;
                padding: 0;
            }
            .actions {
                display: none !important;
            }
            .receipt-container {
                box-shadow: none;
                padding: 4px;
                width: 100% !important;
            }
        }
    </style>
</head>
<body>
    <div class="actions">
        <button onclick="window.print()">🖨️ Cetak Struk (Print)</button>
        <button class="btn-secondary" onclick="toggleWidth()">🔄 Ubah 58mm / 80mm</button>
    </div>

    <div class="receipt-container" id="receipt">
        <div class="text-center">
            <div class="store-name">KIOS AISYHA</div>
            <div class="store-sub">Pusat Sembako Segar & Terjangkau</div>
            <div class="store-sub">Kios Sembako Lingkungan & Delivery</div>
            <div class="store-sub">WA: 0821-5430-6904</div>
        </div>

        <div class="double-dashed"></div>

        <div class="info-row">
            <span>No. Nota</span>
            <span class="bold">{{ $order->code }}</span>
        </div>
        <div class="info-row">
            <span>Tanggal</span>
            <span>{{ $order->created_at->format('d/m/Y H:i') }}</span>
        </div>
        <div class="info-row">
            <span>Pelanggan</span>
            <span>{{ $order->recipient ?? $order->user->name }}</span>
        </div>
        <div class="info-row">
            <span>Metode</span>
            <span>{{ $order->delivery_method == 'pickup' ? 'Ambil di Toko' : 'Diantar ke Rumah' }}</span>
        </div>
        @if($order->address)
        <div class="info-row">
            <span>Alamat</span>
            <span style="max-width: 60%; text-align: right; word-break: break-word;">{{ Str::limit($order->address, 50) }}</span>
        </div>
        @endif

        <div class="dashed"></div>

        <table class="item-table">
            @foreach($order->items as $it)
            <tr>
                <td colspan="2" class="bold">{{ $it->name }}</td>
            </tr>
            <tr>
                <td>{{ $it->quantity }} x Rp{{ number_format($it->price, 0, ',', '.') }}</td>
                <td class="text-right bold">Rp{{ number_format($it->subtotal, 0, ',', '.') }}</td>
            </tr>
            @endforeach
        </table>

        <div class="dashed"></div>

        <div class="total-row">
            <span>Subtotal</span>
            <span>Rp{{ number_format($order->subtotal, 0, ',', '.') }}</span>
        </div>
        @if($order->discount > 0)
        <div class="total-row">
            <span>Diskon ({{ $order->voucher_code }})</span>
            <span>-Rp{{ number_format($order->discount, 0, ',', '.') }}</span>
        </div>
        @endif
        <div class="total-row">
            <span>Ongkos Kirim</span>
            <span>{{ $order->shipping_fee == 0 ? 'GRATIS' : 'Rp'.number_format($order->shipping_fee, 0, ',', '.') }}</span>
        </div>

        <div class="dashed"></div>

        <div class="total-row grand-total">
            <span>TOTAL</span>
            <span>Rp{{ number_format($order->total, 0, ',', '.') }}</span>
        </div>

        <div class="info-row" style="margin-top: 6px;">
            <span>Pembayaran</span>
            <span class="bold">{{ strtoupper($order->payment_method) }} ({{ $order->payment_status == 'paid' ? 'LUNAS' : 'BELUM LUNAS' }})</span>
        </div>

        @if($order->note)
        <div class="info-row" style="margin-top: 4px;">
            <span>Catatan</span>
            <span style="max-width: 65%; text-align: right;">{{ $order->note }}</span>
        </div>
        @endif

        <div class="double-dashed"></div>

        <div class="text-center footer">
            <div>Terima Kasih Telah Berbelanja!</div>
            <div>Berkah & Sehat Selalu Untuk Keluarga</div>
            <div style="margin-top: 4px; font-size: 9px;">Layanan Konsumen / Pesan Ulang via WA: 0821-5430-6904</div>
        </div>
    </div>

    <script>
        function toggleWidth() {
            var el = document.getElementById('receipt');
            el.classList.toggle('w-80');
        }
        // Auto print jika dibuka dengan param ?autoprint=1
        if (window.location.search.includes('autoprint=1')) {
            window.addEventListener('load', function() {
                window.print();
            });
        }
    </script>
</body>
</html>

