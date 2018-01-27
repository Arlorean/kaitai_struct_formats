meta:
  id: qubicle_qb
  file-extension: qb
  application: Qubicle
  endian: le
  license: MIT
  title: Qubicle .qb File
doc: |
  'Qubicle Homepage http://minddesk.com/index.php'
  'Minidesk Qubicle .qb Format Description http://minddesk.com/learn/article.php?id=22'
seq:
  - id: version
    type: u4
    doc: stores the version of the Qubicle Binary file format as major, minor, release, build. Current version is 1.1.0.0.
  - id: color_format_type
    type: u4
    enum: color_format
    doc:  Can be either 0 or 1. If 0 voxel data is encoded as RGBA, if 1 as BGRA.
  - id: z_axis_orientation_type
    type: u4
    enum: z_axis_orientation
    doc:  Can either be 0=left handed or 1=right handed.
  - id: compression_type
    type: u4
    enum: compression
    doc: If set to 1 data is compressed using run length encoding (RLE). If set to 0 data is uncompressed.
  - id: visibility_mask_encoded
    type: u4
    doc: If set to 0 the A value of RGBA or BGRA is either 0 (invisble voxel) or 255 (visible voxel). If set to 1 the visibility mask of each voxel is encoded into the A value telling your software which sides of the voxel are visible. You can save a lot of render time using this option. More info about this in the section visibility-mask encoding.
  - id: matrix_count
    type: u4
    doc: tells you how many matrices are stored in this file.
  - id: matrices
    type: matrix
    repeat: expr
    repeat-expr: matrix_count
types:
  matrix:
    seq:
      - id: name_length
        type: u1
      - id: name
        type: str
        encoding: utf8
        size: name_length
      - id: size_x
        type: u4
      - id: size_y
        type: u4
      - id: size_z
        type: u4
      - id: pos_x
        type: s4
      - id: pos_y
        type: s4
      - id: pos_z
        type: s4
      - id: colors
        if: '_root.compression_type == compression::uncompressed'
        type: color
        repeat: expr
        repeat-expr: 'size_x*size_y*size_z'
      - id: slices
        if: '_root.compression_type == compression::run_length_encoding'
        type: slice
        repeat: expr
        repeat-expr: size_z
  slice:
    seq: 
      - id: blocks
        type: block
        repeat: until
        repeat-until: _.data.i == 6 # NEXT_SLICE_FLAG
  block:
    seq: 
      - id: data
        type: color
      - id: code
        if: data.i == 2 # CODE_FLAG
        type: code
    instances:
      color:
        value: '(data.i == 2 ? code.color : data)'
      count:
        value: '(data.i == 2 ? code.count : (data.i == 6 ? 0 : 1))'
  code:
    seq:
      - id: count
        type: u4
      - id: color
        type: color
  color:
    seq:
      - id: c0
        type: u1
      - id: c1
        type: u1
      - id: c2
        type: u1
      - id: c3
        type: u1
    instances:
      r:
        value: '_root.color_format_type == color_format::rgba ? c0 : c2'
      g:
        value: 'c1'
      b:
        value: '_root.color_format_type == color_format::rgba ? c2 : c0'
      a:
        value: '(_root.visibility_mask_encoded != 0) ? (((c3&1) == 0) ? 0 : 255) : c3'
      i:
        value: 'c0+(c1*256)+(c2*256*256)+(c3*256*256)'
enums:
  color_format:
    0: rgba
    1: bgra
  z_axis_orientation:
    0: left_handed
    1: right_handed
  compression:
    0: uncompressed
    1: run_length_encoding
  compressed_data_type:
    2: code_flag
    6: next_slice_flag