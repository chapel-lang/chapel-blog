! since CAF is SPMD, all processors/images will run a copy of main...
program main
  implicit none

! thus, these declarations are executed by each image, giving each its own copy
  integer, parameter :: n = 1000000      ! the number of random samples to take
  integer :: n_local = n / num_images()  ! the per-image problem size
  real, allocatable :: x(:), y(:)        ! per-image arrays of random coords
  integer :: within_circle[*]            ! a coarray counting points in the circle
  integer :: i                           ! an integer loop counter
  integer :: n_actual                    ! the actual value of 'n' we're using

! the computation of 'n_local' above assumes 'n' divides evenly by #images;
! compute the actual value of 'n' we're ending up with if it doesn't...
  n_actual = n_local * num_images()

! warn if 'n_actual != n' on image 1 only (to avoid printing a warning per image)
  if (n_actual /= n  .AND. this_image() == 1) then
    print *,"warning: only computing ",n_actual,"points, not",n
  end if

! allocate each image's coordinate arrays using the local problem size
  allocate(x(n_local))
  allocate(y(n_local))

! fill each image's local coordinate arrays with random values
  call random_number(x)
  call random_number(y)

! compute how many of each image's coords lie within a quadrant of the unit circle
  within_circle = within_circle + count(x**2 + y**2 < 1.0)

! make sure all images are done computing before reading their results
  sync all

! have image 1...
  if (this_image() == 1) then

! ...add each image's local count to its own, where '[i]' reads image 'i's copy
     do i=2, num_images()
        within_circle = within_circle + within_circle[i]
     end do

! ...print the result
     print *,"pi is approximately", 4.0*within_circle/n_actual
  end if
end program main
