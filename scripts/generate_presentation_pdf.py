#!/usr/bin/env python3
"""
Generate a comprehensive, publication-grade presentation & project defense PDF
for the RISC-V PQC Cryptographic Accelerator (XSHA256) project.
"""

import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether, PageBreak, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_PDF = os.path.join(ROOT_DIR, "RISC_V_PQC_XSHA256_Project_Guide.pdf")

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#718096"))
        
        # Header (Pages 2+)
        if self._pageNumber > 1:
            self.drawString(36, 11 * inch - 28, "RISC-V PQC Cryptographic Accelerator (XSHA256) | Complete Defense Guide")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(36, 11 * inch - 32, 8.5 * inch - 36, 11 * inch - 32)
            
        # Footer
        footer_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(8.5 * inch - 36, 20, footer_text)
        self.drawString(36, 20, "Confidential - Academic & Project Presentation Document")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(36, 30, 8.5 * inch - 36, 30)
        self.restoreState()

def build_pdf():
    doc = SimpleDocTemplate(
        OUTPUT_PDF,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=42,
        bottomMargin=42
    )

    styles = getSampleStyleSheet()
    
    # Custom Palette
    c_primary = colors.HexColor("#1A365D")    # Navy Blue
    c_secondary = colors.HexColor("#2B6CB0")  # Slate Blue
    c_accent = colors.HexColor("#C53030")     # Crimson Accent
    c_dark = colors.HexColor("#2D3748")       # Charcoal
    c_bg_light = colors.HexColor("#F7FAFC")   # Light gray table
    c_callout_bg = colors.HexColor("#EDF2F7") # Code / Box bg
    
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=c_primary,
        alignment=1, # Center
        spaceAfter=6
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=c_secondary,
        alignment=1,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=c_primary,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=c_secondary,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12.5,
        textColor=c_dark,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'BulletDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12.5,
        textColor=c_dark,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=3
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#1A202C")
    )

    code_style = ParagraphStyle(
        'CodeText',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor("#2C5282")
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=10.5,
        textColor=c_dark
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10.5,
        textColor=colors.white
    )

    story = []

    # -------------------------------------------------------------
    # 1. Header Banner
    # -------------------------------------------------------------
    story.append(Paragraph("RISC-V PQC CRYPTOGRAPHIC ACCELERATOR", title_style))
    story.append(Paragraph("<b>RV32I + PicoRV32 + Custom XSHA256 PCPI Extension + SLH-DSA + Artix-7</b><br/>Complete Architectural Blueprint, Implementation Guide, and Live Panel Defense Script", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=c_primary, spaceBefore=0, spaceAfter=12))

    # -------------------------------------------------------------
    # 2. Executive Summary & Pitch
    # -------------------------------------------------------------
    story.append(Paragraph("1. Executive Summary & The High-Impact Pitch", h1_style))
    
    pitch_text = (
        "<b>The 2-Minute Elevator Pitch to the Panel:</b><br/>"
        "<i>\"Distinguished panel members, this project delivers a hardware/software co-designed custom RISC-V cryptographic processor system "
        "engineered to accelerate Post-Quantum Cryptography (PQC) on embedded edge devices. As quantum computing advances, classical algorithms like RSA and ECDSA "
        "will be broken. NIST has standardized <b>SLH-DSA (FIPS 205)</b>—a stateless hash-based digital signature algorithm whose security rests entirely on hash functions like SHA-256.<br/><br/>"
        "On embedded 32-bit RISC-V cores (RV32I), evaluating deep hash chains consumes millions of CPU cycles—computing a single SHA-256 block in pure software takes <b>21,331 cycles</b>. "
        "We engineered <b>XSHA256</b>, a dedicated cryptographic co-processor tightly coupled to a PicoRV32 core via the Pico Co-Processor Interface (PCPI) using the legal RISC-V Custom-0 opcode space. "
        "Our co-processor autonomously generates the message schedule via a 16-word rolling buffer, reducing block compression to <b>736 cycles (28.98&times; speedup)</b> and slashing instructions by <b>96.8%</b>. "
        "When integrated into an end-to-end SLH-DSA-SHA2-128s workload, we achieve an application speedup of up to <b>19.33&times;</b>, requiring only <b>2,582 LUTs (12.4% of an Artix-7 FPGA)</b> with zero Block RAMs or DSPs.\"</i>"
    )
    
    pitch_box = Table(
        [[Paragraph(pitch_text, callout_style)]],
        colWidths=[7.5 * inch]
    )
    pitch_box.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), c_callout_bg),
        ('BOX', (0, 0), (-1, -1), 1, c_secondary),
        ('LEFTPADDING', (0, 0), (-1, -1), 12),
        ('RIGHTPADDING', (0, 0), (-1, -1), 12),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(pitch_box)
    story.append(Spacer(1, 10))

    # -------------------------------------------------------------
    # 3. How We Created New Instructions (Custom ISA Deep Dive)
    # -------------------------------------------------------------
    story.append(Paragraph("2. How We Created New Instructions (RISC-V Custom-0 ISA)", h1_style))
    story.append(Paragraph(
        "A critical question panels ask is: <i>\"How did you create custom instructions without breaking RISC-V compliance or rebuilding GCC?\"</i><br/>"
        "The RISC-V International ISA specification formally reserves four 7-bit opcode spaces for proprietary extensions: "
        "<b>custom-0</b> (<code>7'b0001011 / 0x0B</code>), <b>custom-1</b> (<code>0x2B</code>), <b>custom-2</b> (<code>0x5B</code>), and <b>custom-3</b> (<code>0x7B</code>). "
        "By targeting <code>custom-0</code>, our extension is 100% compliant and cannot collide with standard integer (RV32I), compressed (RVC), floating-point (RV32F), or scalar crypto (Zknh) instructions.",
        body_style
    ))

    # Instruction Table
    isa_headers = ["Mnemonic", "Opcode", "funct3", "funct7", "rs1 / rs2", "rd", "Hardware Action"]
    isa_rows = [
        [
            Paragraph("<b>sha256.init</b>", table_cell_style),
            Paragraph("0x0B", table_cell_style),
            Paragraph("000", table_cell_style),
            Paragraph("0000000", table_cell_style),
            Paragraph("x0 / x0", table_cell_style),
            Paragraph("x0", table_cell_style),
            Paragraph("Resets state A..H to FIPS 180-4 standard IV and clears buffer load index (t=0). 1 cycle latency.", table_cell_style)
        ],
        [
            Paragraph("<b>sha256.load</b>", table_cell_style),
            Paragraph("0x0B", table_cell_style),
            Paragraph("001", table_cell_style),
            Paragraph("0000000", table_cell_style),
            Paragraph("word / x0", table_cell_style),
            Paragraph("x0", table_cell_style),
            Paragraph("Stores 32-bit big-endian message word into circular buffer W[load_idx]; increments load_idx. 1 cycle.", table_cell_style)
        ],
        [
            Paragraph("<b>sha256.round</b>", table_cell_style),
            Paragraph("0x0B", table_cell_style),
            Paragraph("010", table_cell_style),
            Paragraph("0000000", table_cell_style),
            Paragraph("x0 / x0", table_cell_style),
            Paragraph("x0", table_cell_style),
            Paragraph("Executes single compression round; computes W[t] on-the-fly for t &ge; 16. Single-cycle custom instruction.", table_cell_style)
        ],
        [
            Paragraph("<b>sha256.getstate</b>", table_cell_style),
            Paragraph("0x0B", table_cell_style),
            Paragraph("011", table_cell_style),
            Paragraph("0000000", table_cell_style),
            Paragraph("idx (0..7) / x0", table_cell_style),
            Paragraph("state_word", table_cell_style),
            Paragraph("Reads 32-bit accumulated state H[idx] into integer register rd (pcpi_wr = 1). 1 cycle latency.", table_cell_style)
        ],
        [
            Paragraph("<b>sha256.compress</b>", table_cell_style),
            Paragraph("0x0B", table_cell_style),
            Paragraph("100", table_cell_style),
            Paragraph("0000000", table_cell_style),
            Paragraph("x0 / x0", table_cell_style),
            Paragraph("x0", table_cell_style),
            Paragraph("Autonomous 64-round block compression. Asserts pcpi_wait for 64 accelerator clock cycles. Completes with accumulation.", table_cell_style)
        ]
    ]

    isa_table = Table([[Paragraph(h, table_header_style) for h in isa_headers]] + isa_rows, colWidths=[1.1*inch, 0.6*inch, 0.6*inch, 0.7*inch, 0.9*inch, 0.8*inch, 2.8*inch])
    isa_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), c_primary),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, c_bg_light]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(isa_table)
    story.append(Spacer(1, 8))

    # Code snippet showing both software and hardware sides
    code_text = (
        "<b>Software Emission (C Inline Assembly via GCC .insn Directive):</b><br/>"
        "<code>static inline void xsha256_load(uint32_t word) {<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;asm volatile (\".insn r 0x0B, 0x1, 0x00, x0, %0, x0\" : : \"r\"(word));<br/>"
        "}<br/>"
        "static inline void xsha256_compress(void) {<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;asm volatile (\".insn r 0x0B, 0x4, 0x00, x0, x0, x0\");<br/>"
        "}</code><br/><br/>"
        "<b>Hardware PCPI Decoding (rtl/pcpi/xsha256_pcpi.sv):</b><br/>"
        "<code>wire is_custom0 = pcpi_valid && (pcpi_insn[6:0] == 7'b0001011);<br/>"
        "wire is_load    = is_custom0 && (pcpi_insn[14:12] == 3'b001); // funct3 = 1<br/>"
        "wire is_compress= is_custom0 && (pcpi_insn[14:12] == 3'b100); // funct3 = 4</code>"
    )
    code_box = Table([[Paragraph(code_text, code_style)]], colWidths=[7.5 * inch])
    code_box.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F7FAFC")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E0")),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(code_box)
    story.append(Spacer(1, 10))

    # -------------------------------------------------------------
    # 4. Hardware Microarchitecture & Rolling Message Buffer
    # -------------------------------------------------------------
    story.append(Paragraph("3. Microarchitecture: The 16-Word Rolling Schedule Unit", h1_style))
    story.append(Paragraph(
        "Standard SHA-256 expands 16 message words into 64 words: "
        "<b>W<sub>t</sub> = &sigma;<sub>1</sub>(W<sub>t-2</sub>) + W<sub>t-7</sub> + &sigma;<sub>0</sub>(W<sub>t-15</sub>) + W<sub>t-16</sub></b>.<br/>"
        "Storing all 64 words requires 2,048 flip-flops. However, notice that round <i>t</i> only depends on words up to 16 positions in the past. "
        "We designed a <b>16-word circular buffer (W[0..15])</b> using modulo-16 indexing:<br/>"
        "&bull; <code>idx_m2 = (t - 2) & 15</code> | <code>idx_m7 = (t - 7) & 15</code> | <code>idx_m15 = (t - 15) & 15</code> | <code>idx_m16 = (t - 16) & 15 = t & 15</code><br/>"
        "At round <i>t</i>, the hardware computes W<sub>calc</sub>, feeds it to the round datapath, and at the clock edge overwrites <code>W[t & 15]</code>. "
        "That slot held W<sub>t-16</sub>, which will never be accessed again. <b>This mathematical invariant saves 1,536 flip-flops (75% of buffer area)</b> with zero stalls.",
        body_style
    ))

    # -------------------------------------------------------------
    # 5. Software Toolchain Ecosystem & Connecting the Lifecycle
    # -------------------------------------------------------------
    story.append(Paragraph("4. Software Toolchain Ecosystem: How Everything Connects", h1_style))
    story.append(Paragraph(
        "A key goal of this project was connecting the full toolchain across software, simulation, synthesis, and post-quantum application benchmarking:",
        body_style
    ))
    
    tools_data = [
        ["Tool / Package", "Exact Version", "Role in Project Lifecycle", "Why It Was Chosen"],
        [
            Paragraph("<b>xPack GNU RISC-V GCC</b>", table_cell_style),
            Paragraph("15.2.0 (rv32i/ilp32)", table_cell_style),
            Paragraph("Compiles bare-metal RV32I startup, C baseline, and inline .insn firmware into ELF and hex.", table_cell_style),
            Paragraph("Guarantees clean RV32I assembly without relying on multiplication (M) or compressed (C) extensions.", table_cell_style)
        ],
        [
            Paragraph("<b>Icarus Verilog & VVP</b>", table_cell_style),
            Paragraph("14.0 (devel) (-g2012)", table_cell_style),
            Paragraph("Simulates standalone RTL testbenches and runs the full SoC cycle-accurate execution with firmware.", table_cell_style),
            Paragraph("Fast, open-source, standards-compliant IEEE 1364/1800 simulation engine.", table_cell_style)
        ],
        [
            Paragraph("<b>Yosys Open Synthesis</b>", table_cell_style),
            Paragraph("0.70+336", table_cell_style),
            Paragraph("Performs real technology mapping to AMD/Xilinx Artix-7 primitives (LUTs, FFs, CARRY4).", table_cell_style),
            Paragraph("Provides verifiable, open-source FPGA resource and cell-count utilization reports.", table_cell_style)
        ],
        [
            Paragraph("<b>AMD Vivado Suite</b>", table_cell_style),
            Paragraph("2022+ Compatible", table_cell_style),
            Paragraph("Physical implementation script (synth.tcl) and pin/timing constraints (arty_a7.xdc).", table_cell_style),
            Paragraph("Industry standard for timing closure, clock frequency estimation (Fmax), and bitstream generation.", table_cell_style)
        ],
        [
            Paragraph("<b>Ripes Simulator</b>", table_cell_style),
            Paragraph("v2.3.1 (AppImage)", table_cell_style),
            Paragraph("Visual microarchitecture exploration and cycle-accurate pipeline inspection.", table_cell_style),
            Paragraph("Allows stepping through pipeline hazards, branch penalties, and register states.", table_cell_style)
        ],
        [
            Paragraph("<b>Python 3 + Matplotlib</b>", table_cell_style),
            Paragraph("Python 3.10", table_cell_style),
            Paragraph("Automated benchmark runner, CSV/JSON data logging, and publication chart generator.", table_cell_style),
            Paragraph("Ensures all reported numbers and LaTeX tables are reproducible from raw simulation logs.", table_cell_style)
        ]
    ]

    tool_table = Table([[Paragraph(h, table_header_style) for h in tools_data[0]]] + tools_data[1:], colWidths=[1.5*inch, 1.2*inch, 2.5*inch, 2.3*inch])
    tool_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), c_primary),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, c_bg_light]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(tool_table)
    story.append(Spacer(1, 14))

    # Page Break for Results & Live Demo
    story.append(PageBreak())

    # -------------------------------------------------------------
    # 6. Experimental Results & Visual Charts
    # -------------------------------------------------------------
    story.append(Paragraph("5. Experimental Results: Primitive & Post-Quantum Workload", h1_style))
    story.append(Paragraph(
        "All measurements were captured directly from the 64-bit hardware cycle counter and instruction retirement counter inside the SoC:",
        body_style
    ))

    # Primitive Benchmark Table
    prim_headers = ["Config", "Architecture Description", "CPU Cycles", "Instructions", "CPI", "Speedup vs C1"]
    prim_rows = [
        ["C1", "RV32I Software Baseline", "21,331", "5,336", "4.00", "1.00x"],
        ["C2", "RV32I + Zknh Scalar Reference", "21,335", "5,337", "4.00", "0.99x"],
        ["C3", "RV32I + XSHA256 Round PCPI (Fine-Grained)", "1,672", "359", "4.66", "12.75x"],
        ["C4", "RV32I + XSHA256 Block PCPI (Coarse-Grained)", "736", "172", "4.28", "<b>28.98x</b>"]
    ]
    prim_table = Table([[Paragraph(h, table_header_style) for h in prim_headers]] + 
                       [[Paragraph(c, table_cell_style) for c in r] for r in prim_rows], 
                       colWidths=[0.8*inch, 3.1*inch, 0.9*inch, 0.9*inch, 0.8*inch, 1.0*inch])
    prim_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), c_primary),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, c_bg_light]),
        ('ALIGN', (2, 1), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(prim_table)
    story.append(Spacer(1, 8))

    # SLH-DSA Table & FPGA Utilization Table
    pqc_headers = ["SLH-DSA Workload Operation", "Baseline RV32I (Cycles)", "Accelerated XSHA256 (Cycles)", "Application Speedup", "Status"]
    pqc_rows = [
        ["Key Generation (KeyGen)", "1,301,078", "67,302", "<b>19.33x</b>", "PASSED"],
        ["Signature Generation (Sign)", "477,987", "25,597", "<b>18.67x</b>", "PASSED"],
        ["Signature Verification (Verify)", "825,728", "44,334", "<b>18.62x</b>", "PASSED"],
        ["Negative Verification (1-bit corrupt)", "Rejected", "Rejected", "Expected Failure", "PASSED"]
    ]
    pqc_table = Table([[Paragraph(h, table_header_style) for h in pqc_headers]] + 
                      [[Paragraph(c, table_cell_style) for c in r] for r in pqc_rows], 
                      colWidths=[2.3*inch, 1.4*inch, 1.6*inch, 1.2*inch, 1.0*inch])
    pqc_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), c_secondary),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, c_bg_light]),
        ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(pqc_table)
    story.append(Spacer(1, 8))

    # Artix-7 Synthesis Table
    fpga_headers = ["Subsystem (Synthesized on Artix-7 XC7A35T)", "LUTs", "Flip-Flops (FF)", "Carry4", "BRAM", "DSP", "% of Device"]
    fpga_rows = [
        ["XSHA256 PCPI Accelerator Unit", "2,582", "1,078", "102", "0", "0", "<b>12.4%</b>"],
        ["Complete RISC-V SoC (PicoRV32 + 128KB + Accel)", "7,170", "1,883", "233", "0", "0", "<b>34.5%</b>"],
        ["Artix-7 XC7A35T Total Available Resources", "20,800", "41,600", "5,200", "50", "90", "100.0%"]
    ]
    fpga_table = Table([[Paragraph(h, table_header_style) for h in fpga_headers]] + 
                       [[Paragraph(c, table_cell_style) for c in r] for r in fpga_rows], 
                       colWidths=[2.8*inch, 0.7*inch, 0.9*inch, 0.7*inch, 0.6*inch, 0.6*inch, 1.2*inch])
    fpga_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#4A5568")),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, c_bg_light]),
        ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(fpga_table)
    story.append(Spacer(1, 10))

    # Embed Visual Plots side by side or sequentially
    fig1_path = os.path.join(ROOT_DIR, "paper/figures/sha256_speedup.png")
    fig2_path = os.path.join(ROOT_DIR, "paper/figures/slhdsa_end_to_end_speedup.png")
    
    if os.path.exists(fig1_path) and os.path.exists(fig2_path):
        img1 = Image(fig1_path, width=3.6*inch, height=2.4*inch)
        img2 = Image(fig2_path, width=3.6*inch, height=2.4*inch)
        img_table = Table([[img1, img2]], colWidths=[3.75*inch, 3.75*inch])
        img_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
        ]))
        story.append(img_table)
        story.append(Spacer(1, 10))

    # -------------------------------------------------------------
    # 7. Live Demonstration Commands & Script for the Panel
    # -------------------------------------------------------------
    story.append(Paragraph("6. Live Demonstration Script for the Panel (Exact Commands)", h1_style))
    story.append(Paragraph(
        "Execute this sequence of commands live in the terminal while presenting to the jury:",
        body_style
    ))

    demo_steps = [
        ("Step 1: Set Up & Verify Environment", "source scripts/setup_env.sh",
         "Validates cross-compiler (GCC 15.2 rv32i) and EDA tools (Icarus, Verilator, Yosys). Explain to panel that setup is completely reproducible."),
        ("Step 2: Verify Standalone SHA-256 RTL Core", "make tb_sha",
         "Tests hardware round datapath & rolling schedule buffer against NIST FIPS 180-4 'abc' vector. Proves RTL passes with 0 errors."),
        ("Step 3: Verify PCPI Interface Handshake", "make tb_pcpi",
         "Tests co-processor decoder on RISC-V Custom-0 opcode (0x0B). Verifies single-cycle ready and multi-cycle 64-cycle wait/ready handshaking."),
        ("Step 4: Full RV32I SoC Execution & Benchmark (Main Event)", "make sim",
         "Compiles bare-metal C firmware, boots PicoRV32 SoC, executes C1-C4 benchmarks, runs SLH-DSA-SHA2-128s, and verifies 100% digest correctness."),
        ("Step 5: Artix-7 FPGA Resource Utilization", "cat experiments/synthesis/artix7_resource_utilization.csv",
         "Displays physical hardware cell count: 2,582 LUTs (12.4% of Artix-7), 1,078 FFs, 0 BRAM, 0 DSP.")
    ]

    for title, cmd, desc in demo_steps:
        box_content = (
            f"<b>{title}</b><br/>"
            f"<code>$ {cmd}</code><br/>"
            f"<i>What to say: {desc}</i>"
        )
        t = Table([[Paragraph(box_content, table_cell_style)]], colWidths=[7.5 * inch])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#EDF2F7")),
            ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
            ('RIGHTPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        story.append(t)
        story.append(Spacer(1, 4))

    story.append(Spacer(1, 6))

    # -------------------------------------------------------------
    # 8. Anticipated Panel Questions & Bulletproof Answers
    # -------------------------------------------------------------
    story.append(Paragraph("7. Anticipated Technical Panel Questions & Bulletproof Answers", h1_style))
    
    qa_list = [
        ("Q: Why did you connect via PCPI instead of an AXI4/DMA bus?",
         "In SLH-DSA, hashing occurs in thousands of short 32-byte and 64-byte blocks along WOTS+ chains. An AXI DMA engine introduces major register setup, bus arbitration, and interrupt latency overheads that exceed the compute time. PCPI enables zero-latency instruction dispatch directly from the CPU pipeline."),
        ("Q: Why does the rolling buffer use 16 words instead of 64 words? Doesn't it overwrite data?",
         "SHA-256 recurrence W[t] = sig1(W[t-2]) + W[t-7] + sig0(W[t-15]) + W[t-16] only accesses words from up to 16 cycles ago. Using modulo-16 indexing, W[t & 15] is read, computed, and overwritten at the clock edge. The overwritten value held W[t-16], which will never be accessed again. This saves 1,536 flip-flops (75% buffer area)."),
        ("Q: Why is the SLH-DSA speedup (18.6x - 19.3x) lower than the raw SHA-256 speedup (28.98x)?",
         "This is an empirical validation of Amdahl's Law. In SLH-DSA, hashing accounts for ~95% of execution, but 5% consists of unaccelerated software tasks: ADRS address structure manipulation, Merkle tree traversal, and message nibble extraction. By Amdahl's Law, maximum theoretical speedup is capped at ~19x."),
        ("Q: What are the trade-offs between C3 (round-level) and C4 (block-level)?",
         "C3 gives fine-grained software control to pause or inspect states, but pays CPU instruction fetch and branch loop overhead (1,672 cycles). C4 executes all 64 rounds autonomously in 64 clock cycles via an internal state machine (736 cycles, 2.27x faster than C3) for under 40 additional LUTs of control logic.")
    ]

    for q, a in qa_list:
        qa_content = f"<b>{q}</b><br/>{a}"
        story.append(Paragraph(qa_content, bullet_style))
        story.append(Spacer(1, 4))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"[SUCCESS] Generated complete defense guide PDF: {OUTPUT_PDF}")

if __name__ == "__main__":
    build_pdf()

