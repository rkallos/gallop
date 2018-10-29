class BoundedQueue[A: Any #share]
  let _size: USize
  let _arr: Array[(A | None)]
  var _eq_idx: USize = 0
  var _dq_idx: USize = 0

  new create(size': USize) =>
    _size = size'
    _arr = Array[(A | None)].init(None, size')

  fun ref enqueue(elem: A)? =>
    if _arr(_eq_idx)? is None then
      let idx = _eq_idx
      _eq_idx = _eq_idx + 1
      _arr(idx % _size)? = elem
    else
      // queue is full
      error
    end

  fun ref dequeue(): A^? =>
    if _dq_idx < _eq_idx then
      let idx = _dq_idx
      _dq_idx = _dq_idx + 1
      (_arr(idx % _size)? = None) as A^
    else
      // queue is empty
      error
    end

  fun size(): USize =>
    _eq_idx - _dq_idx
