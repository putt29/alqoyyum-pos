"""Terbilang (angka -> kata) meniru hasil kwitansi Excel.

Excel memakai add-in "Kombinasi Terbilang" lalu PROPER(), sehingga hasilnya
mis. 739000 -> "Tujuhratus Tigapuluh Sembilan Ribu Rupiah" (ratus/puluh/belas
digabung dengan angka di depannya). Gaya ini adalah default (joined=True).
joined=False menghasilkan ejaan baku: "Tujuh Ratus Tiga Puluh Sembilan Ribu Rupiah".
"""
_SATUAN = ["", "satu", "dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan", "sembilan"]
_GROUPS = ((10 ** 12, "triliun"), (10 ** 9, "miliar"), (10 ** 6, "juta"), (10 ** 3, "ribu"))


def _tiga_digit(n: int, joined: bool) -> str:
    """Kata untuk 1..999 (tanpa kata 'ribu', dll.)."""
    j = "" if joined else " "
    out = []
    ratus, sisa = divmod(n, 100)
    if ratus == 1:
        out.append("seratus")
    elif ratus > 1:
        out.append(_SATUAN[ratus] + j + "ratus")
    puluh, satuan = divmod(sisa, 10)
    if sisa == 0:
        pass
    elif sisa < 10:
        out.append(_SATUAN[sisa])
    elif sisa == 10:
        out.append("sepuluh")
    elif sisa == 11:
        out.append("sebelas")
    elif sisa < 20:
        out.append(_SATUAN[satuan] + j + "belas")
    else:
        out.append(_SATUAN[puluh] + j + "puluh")
        if satuan:
            out.append(_SATUAN[satuan])
    return " ".join(out)


def terbilang(n: int, joined: bool = True) -> str:
    """Angka bulat >= 0 -> kata huruf kecil (tanpa 'rupiah')."""
    if n < 0:
        raise ValueError("terbilang: angka negatif tidak didukung")
    if n >= 10 ** 15:
        raise ValueError("terbilang: angka terlalu besar")
    if n == 0:
        return "nol"
    parts = []
    rest = n
    for size, name in _GROUPS:
        q, rest = divmod(rest, size)
        if q == 0:
            continue
        if name == "ribu" and q == 1:
            parts.append("seribu")
        elif q == 1:
            parts.append("satu " + name)
        else:
            parts.append(_tiga_digit(q, joined) + " " + name)
    if rest:
        parts.append(_tiga_digit(rest, joined))
    return " ".join(parts)


def terbilang_rupiah(n: int, joined: bool = True) -> str:
    """Seperti Excel: PROPER(terbilang(total)) & ' Rupiah'."""
    words = terbilang(n, joined)
    return " ".join(w.capitalize() for w in words.split()) + " Rupiah"
