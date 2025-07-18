module temperatures
  use iso_c_binding
  contains
  subroutine FtoC(arr, len) bind(C, name='FtoC')
    integer(c_int), intent(in) :: len
    real(c_double), intent(inout), dimension(len) :: arr
    
    arr = (arr - 32.0) * 5.0 / 9.0
  end subroutine FtoC

  subroutine CtoF(arr, len) bind(C, name='CtoF')
    integer(c_int), intent(in) :: len
    real(c_double), intent(inout), dimension(len) :: arr
    
    arr = arr * 9.0 / 5.0 + 32.0
  end subroutine CtoF
end module temperatures