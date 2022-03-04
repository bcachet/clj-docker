(ns exo.add-test
  (:require [clojure.test :refer [deftest is]]
            [exo.add :refer [sum]]))


(deftest sum-all-things
  (is (= (sum 1 2 3)
         6)))
(deftest will-fail
  (is (= 1 (sum 1 1))))
